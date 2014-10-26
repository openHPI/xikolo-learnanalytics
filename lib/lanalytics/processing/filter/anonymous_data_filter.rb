module Lanalytics
  module Processing
    module Filter

      class AnonymousDataFilter < Lanalytics::Processing::ProcessingStep

        def filter(original_resource_as_hash, processed_resources, opts = nil)

          processed_resources.map! do | processed_resource |
            next unless processed_resource.is_a? Lanalytics::Model::StmtResource
            processed_resource.properties.delete_if { |key, value| symbol_anonymous?(key) }
            processed_resource
          end
        end
        alias_method :process, :filter

        private
        def symbol_anonymous?(symbol)
          %w(email name password).each do | dangerous_keyword |
            return true if symbol.to_s.include?(dangerous_keyword)
          end
          return false
        end

      end

    end
  end
end
