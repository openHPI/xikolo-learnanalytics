module Lanalytics
  module Processing
    module Filter

      class AnonymousDataFilter < Lanalytics::Processing::ProcessingStep

        def filter(original_resource_as_hash, processed_resources, opts = nil)

          processed_resources.map! do | processed_entity |
            if processed_entity.is_a? Lanalytics::Model::StmtResource or processed_entity.is_a? Lanalytics::Model::ResourceRelationship
              processed_entity.properties.delete_if { |key, value| symbol_anonymous?(key) }
              processed_entity
            else
              processed_entity
            end
          end
        end
        alias_method :process, :filter

        private
        def symbol_anonymous?(symbol)
          %w(mail email name password).each do | dangerous_keyword |
            return true if symbol.to_s.include?(dangerous_keyword)
          end
          return false
        end

      end

    end
  end
end
