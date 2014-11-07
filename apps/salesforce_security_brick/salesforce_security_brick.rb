# encoding: utf-8

require 'gooddata'
require './user_hierarchies/lib/user_hierarchies'
require './overflow_hash'
require 'zip'

# Share id has to be named ObjectId
# Role Id has to be named RoleId

module GoodData::Bricks
  class SalesforceSecurityBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end
    
    def initialize(options = {})
       super()
       
       # Should be the result csv zipped? (each file in separate zip)
       @zip_result = options[:zip_result] || true
       
       # How many records of the visibility hash should be stored in memory?
       # Implementation uses overflow hash - the rest of the records is stored on disk (GDBM database)
       # 6000000 should work for the platform setup (3GB of memory)
       @inmemory_records_nr = options[:inmemory_records_nr] || 6000000
    end

    def call(params)
      users_filename = params['users_filename'] || 'User.csv'
      user_roles_filename = params['user_roles_filename'] || 'UserRole.csv'
      groups_filename = params['groups_filename'] || 'Group.csv'
      group_members_filename = params['group_members_filename'] || 'GroupMember.csv'
      permissions_filename = params['permissions_filename'] || 'ObjectPermissions.csv'
      permission_sets_filename = params['permission_sets_filename'] || 'PermissionSet.csv'

      to_process = params['to_process']

      csv_params = { headers: true, return_headers: false, encoding: "ISO-8859-1" }
      users = CSV.parse(File.open(users_filename, 'r:UTF-8').read, csv_params)
      roles = CSV.parse(File.open(user_roles_filename, 'r:UTF-8').read, csv_params)

      groups = CSV.parse(File.open(groups_filename, 'r:UTF-8').read, csv_params)
      group_members = CSV.parse(File.open(group_members_filename, 'r:UTF-8').read, csv_params)
      permission = CSV.parse(File.open(permissions_filename, 'r:UTF-8').read, csv_params)
      permission_set = CSV.parse(File.open(permission_sets_filename, 'r:UTF-8').read, csv_params)

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
      to_process.each do |vals|
        resolve_shares(vals['shares_filename'], vals['objects_filename'], vals['output_filename'], vals['share_id_field'], vals['permission_object_type'], params, {super_users: super_users})
      end
    end

    def resolve_shares(shares_filename, objects_filename, output_filename, share_id_field, permission_object_type, params, inner_params)
      super_users = inner_params[:super_users]
      csv_params = { headers: true, return_headers: false, encoding: "ISO-8859-1" }
      $resolve_group_cache = {}
      visibility = OverflowHash.new(@inmemory_records_nr)      
      count = 0

      CSV.open(output_filename, 'w') do |csv|
        csv << ['user_id', 'object_id']

        # Resolve the share rules
        CSV.foreach(File.open(shares_filename, 'r:UTF-8'), csv_params) do |share|
        # shares.map do |share|
          count += 1
          puts count if count % 10000 == 0
          share = share.to_hash
          stuff = resolve_share_or_group_member(share,nil)
          # if count % 1000 == 0

          stuff.select {|x| x.IsActive == 'true'}.each do |x|
            unless visibility.key?([x.Id, share[share_id_field]].join)
              csv << [x.Id, share[share_id_field]]
              visibility[[x.Id, share[share_id_field]].join] = "1"
            end
          end
          nil
        end

        # Resolve super users
        count = 0
        filtered_super_users = super_users.select { |x| x['SobjectType'] == permission_object_type }
        puts "Resolving Super users"
        CSV.foreach(File.open(objects_filename, 'r:UTF-8'), csv_params) do |row|
          count += 1
          puts count if count % 1000 == 0
          filtered_super_users.each do |u|
            unless visibility.key?([u['Id'], row['Id']].join)
              csv << [u['Id'], row['Id']]
              visibility[[u['Id'], row['Id']].join] = "1"
            end
          end
        end
      end
      
      file_to_upload = output_filename
      if(@zip_result)
          file_to_upload = zip_file(File.open(output_filename, 'r'))	  
       end 
      (params["gdc_files_to_upload"] ||= []) << {:path => file_to_upload}
    end

    def zip_file(file)
      file_basename = File.basename(file)
      zip_filename = file_basename + '.zip'
      File.open(zip_filename, 'w') do |zip|
        Zip::File.open(zip.path, Zip::File::CREATE) do |zipfile|
          zipfile.add(file_basename, file.path)
        end
      end
      zip_filename
    end

    def user?(user_hieararchy, id)
      !!user_hieararchy.find_by_id(id)
    end

    def resolve_group(group, includeBosses = nil)
      includeBosses = group['DoesIncludeBosses'] if includeBosses.nil?
      users_to_resolve = case group['Type']
        when 'Role'
          ($role_lookup[group['RelatedId']] || []) # WHAT IF role doesnt include any users but there are users in manager role and group should include bosses?
        when 'RoleAndSubordinates'
          ($role_lookup[group['RelatedId']] || []).mapcat {|u| u.all_subordinates_with_self}
        # !! ADD Internal
        when 'RoleAndSubordinatesInternal'
          $role_lookup[group['RelatedId']].select {|u| ['None', 'Standard'].include?(u.PortalType)}.map {|u| $user_hieararchy.find_by_id(u[:Id])}.mapcat {|u| u.all_subordinates_with_self }.select {|u| ['None', 'Standard'].include?(u.PortalType) }
        else
          members = $group_members_lookup[group['Id']] || []
          # puts "Mapcating"
          res = members.mapcat {|member| resolve_share_or_group_member(member,includeBosses)}
          # puts "done"
          res
        end
      x = includeBosses == 'true' ? users_to_resolve.mapcat { |u| u.all_managers_with_self } : users_to_resolve
      y = x.uniq
      $resolve_group_cache[[group, includeBosses]] = y 
      y
    end

    def resolve_share_or_group_member(obj,includeBosses)
      id = obj['UserOrGroupId']
      is_user = user?($user_hieararchy, id)
      if is_user
        if includeBosses.nil? or includeBosses == 'true'
          [$user_hieararchy.find_by_id(id)].mapcat {|u| u.all_managers_with_self } 
        else 
          [$user_hieararchy.find_by_id(id)]
        end
      else
        group = $group_lookup[id].first.to_hash
        ib = includeBosses.nil? ? 'false' : 'true'
        result = $resolve_group_cache[[group, ib]] || resolve_group(group, includeBosses)
      end
    rescue
      # puts "GROUP WITH ID #{id} does not exist"
      []
    end
  end
end



