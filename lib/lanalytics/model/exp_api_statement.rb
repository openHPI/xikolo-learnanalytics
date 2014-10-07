require 'date'

module Lanalytics::Model
  # Always a directed grpah d
  class ExpApiStatement
    attr_accessor :user, :verb, :ressource, :timestamp, :with_result, :in_context


    # ::TODO think about encapsulating the user and ressource
    def initialize(user, verb, ressource, timestamp = DateTime.now, result = {}, context = {})
      @user = user
      @verb = verb
      @ressource = ressource
      @with_result = result
      @in_context = context
      @timestamp = timestamp
    end

    #def actor_uuid
    #
    #end
    #
    #def ressource_uuid
    #  return self.ressource.uuid
    #end

    # Implementing the required interface for marshalling objects, see http://ruby-doc.org/core-2.1.3/Marshal.html
    def marshal_dump
      [@user, @verb, @ressource, @timestamp, @with_result, @in_context]
    end

    def marshal_load(serialized_stmt_array)
      @user, @verb, @ressource, @timestamp, @with_result, @in_context = serialized_stmt_array
    end

    # All static methods
    class << self
      def from(serialized_stmt = nil)

        return nil unless serialized_stmt


      end


    end
  end
end