# encoding: UTF-8

require_relative '../metadata'

module GoodData
  class ScheduledEmail < MdObject
    root_key :scheduledMail

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('scheduledmails', ScheduledEmail, options)
      end
    end
  end
end
