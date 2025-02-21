# frozen_string_literal: true

module Lanalytics
  module Processing
    module LoadORM
      class CustomLoadCommand
        attr_reader :loader_type, :query

        def self.sql_for(loader_type, query)
          new(loader_type, query)
        end

        def initialize(loader_type, query)
          raise ArgumentError.new 'Loader type cannot be nil.' unless loader_type

          @loader_type = loader_type.to_sym.downcase
          @query       = query.to_s
        end
      end
    end
  end
end

# UPDATE observed_events
# SET observed_event_duration = 60
# WHERE
#   user_id = '00000001-3100-4444-9999-000000000002'
#   AND observed_event_duration IS NULL
#   AND (current_timestamp - observed_event_timestamp) > ('60 min'::interval);

# UPDATE observed_events
# SET observed_event_duration = (extract(epoch from timestamp '2014-12-04T12:07:00Z') -
#   extract(epoch from observed_event_timestamp)) / 60::float
# WHERE
#   user_id = '00000001-3100-4444-9999-000000000002'
#   AND observed_event_duration IS NULL;
