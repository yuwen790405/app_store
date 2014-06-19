require 'bundler/setup'
require 'gooddata'
require 'user_hierarchies'
require 'csv'
require 'benchmark'
require 'pry'

# {
#   user:
#   role:
#   group:
#   group_member:
#   shares:
#   output_file:
# }

# Share id has to be named ObjectId
# Role Id has to be named RoleId

module GoodData::Bricks
  class SalesforceSecurityBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end

    def call(params)
      users_filename = params['users_filename'] || 'User.csv'
      user_roles_filename = params['user_roles_filename'] || 'UserRole.csv'
      groups_filename = params['groups_filename'] || 'Group.csv'
      group_members_filename = params['group_members_filename'] || 'GroupMember.csv'
      permissions_filename = params['permissions_filename'] || 'ObjectPermissions.csv'
      permission_sets_filename = params['permission_sets_filename'] || 'PermissionSet.csv'

      shares_filenames = params['shares_filenames']
      objects_filenames = params['objects_filenames']
      output_filenames = params['results_filenames']
      permission_object_types = params['permission_object_types']

      csv_params = { headers: true, return_headers: false }
      users = CSV.parse(File.read(users_filename), csv_params)
      roles = CSV.parse(File.read(user_roles_filename), csv_params)

      groups = CSV.parse(File.read(groups_filename), csv_params)
      group_members = CSV.parse(File.read(group_members_filename), csv_params)
      permission = CSV.parse(File.read(permissions_filename), csv_params)
      permission_set = CSV.parse(File.read(permission_sets_filename), csv_params)

      $group_lookup = GoodData::Helpers.create_lookup(groups, 'Id')
      $group_members_lookup = GoodData::Helpers.create_lookup(group_members, 'GroupId')
      roles.each {|x| x['RoleId'] = x['Id']}
      merged_users = GoodData::Helpers.join(users, roles, ['UserRoleId'], ['RoleId'], :full_outer => true)

      merged_permissions = GoodData::Helpers.join(permission, permission_set, ['ParentId'], ['Id'])
      merged_permissions_users = GoodData::Helpers.join(users, merged_permissions, ['ProfileId'], ['ProfileId'])
      filtered_permission_user = merged_permissions_users.select { |x| x['PermissionsViewAllRecords'] == 'true' }
      super_users = filtered_permission_user.select {|u| u['IsActive'] == 'true'}

      $user_hieararchy = GoodData::UserHierarchies::UserHierarchy.build_hierarchy(merged_users, {
        :hashing_id => :Id,
        :id => :RoleId,
        :manager_id => :ParentRoleId
      })

      $role_hierarchy = GoodData::UserHierarchies::UserHierarchy.build_hierarchy(roles, {
        :id => :RoleId,
        :manager_id => :ParentRoleId
      })

      $role_lookup = {}
      $user_hieararchy.users.each do |x|
        key = x.UserRoleId
        $role_lookup[key] = [] unless $role_lookup.key?(key)
        $role_lookup[key] << x
      end

  # -----------------------
      share_id_fields = params['share_id_fields']
      shares_filenames.zip(objects_filenames, output_filenames, share_id_fields, permission_object_types).each do |x, y, z, w, v|
        resolve_shares(x, y, z, w, v, params.merge(super_users: super_users))
      end
    end

    def resolve_shares(shares_filename, objects_filename, output_filename, share_id_field, permission_object_type, params)
  
      super_users = params[:super_users]
      csv_params = { headers: true, return_headers: false }
      shares = CSV.parse(File.read(shares_filename), csv_params)

      $resolve_group_cache = {}
      visibility = {}
      # Resolve the share rules
      shares.each do |share|
        share = share.to_hash
        stuff = resolve_share_or_group_member(share)
        stuff.select {|x| x.IsActive == 'true'}.each do |x|
          visibility[[x.Id, share[share_id_field]]] = 1
        end
      end

      # Resolve super users
      filtered_super_users = super_users.select { |x| x['SobjectType'] == permission_object_type }
      CSV.foreach(objects_filename, csv_params) do |row|
        filtered_super_users.each do |u|
          visibility[[u['Id'], row['Id']]] = 1
        end
      end

      # Serialize to CSV
      CSV.open(output_filename, 'w') do |csv|
        csv << ['user_id', 'object_id']
        visibility.each do |k, v|
          csv << k
        end
      end
    end

    def resolve_group(group)
      users_to_resolve = case group['Type']
        when 'Role'
          ($role_lookup[group['RelatedId']] || [])
        when 'RoleAndSubordinates'
          ($role_lookup[group['RelatedId']] || []).mapcat {|u| u.all_subordinates_with_self}
        # !! ADD Internal
        when 'RoleAndSubordinatesInternal'
          $role_lookup[group['RelatedId']].select {|u| ['None', 'Standard'].include?(u.PortalType)}.map {|u| $user_hieararchy.find_by_id(u[:Id])}.mapcat {|u| u.all_subordinates_with_self }.select {|u| ['None', 'Standard'].include?(u.PortalType) }
        else
          members = $group_members_lookup[group['Id']] || []
          members.mapcat {|member| resolve_share_or_group_member(member)}
        end
      x = group['DoesIncludeBosses'] == 'true' ? users_to_resolve.mapcat { |u| u.all_managers_with_self } : users_to_resolve
      $resolve_group_cache[group] = x
      x
    end

    def user?(user_hieararchy, id)
      !!user_hieararchy.find_by_id(id)
    end

    def resolve_share_or_group_member(obj)
      id = obj['UserOrGroupId']
      is_user = user?($user_hieararchy, id)
      if is_user
        [$user_hieararchy.find_by_id(id)].mapcat {|u| u.all_managers_with_self }
      else
        group = $group_lookup[id].first.to_hash
        result = $resolve_group_cache[group] || resolve_group(group)
      end
    end
  end
end
