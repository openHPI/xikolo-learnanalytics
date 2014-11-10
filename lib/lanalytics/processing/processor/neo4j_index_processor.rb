module Lanalytics
  module Processing
    module Processor
      class Neo4jIndexProcessor < Lanalytics::Processing::ProcessingStep
        
        @@indexed_node_types = nil

        def process(original_resource_as_hash, processed_resources, opts = {})
          
          retrieve_available_indexed_node_types unless @@indexed_node_types

          processed_resources.each do | processed_resource |
            create_index_for_resource(processed_resource) unless available_indexed_node_types.include?(processed_resource.type)
          end
        end

        def retrieve_available_indexed_node_types

          @@indexed_node_types = Set.new 
          indexes_json = MultiJson.load(RestClient.get("#{Neo4j::Session.current.resource_url}schema/index"), symbolize_keys: true)
          indexes_json.each { | index_json | @@indexed_node_types.add(index_json[:label].to_sym.upcase) }
        end

        def create_index_for_resource(resource)
          Neo4j::Session.query("CREATE INDEX ON :#{resource.type}(resource_uuid)")
          @@indexed_node_types.add(resource.type) 
        end

        def available_indexed_node_types
          return @@indexed_node_types ? @@indexed_node_types.to_a : []
        end
      end
    end
  end
end
