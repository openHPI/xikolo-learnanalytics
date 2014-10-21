module Lanalytics
  module Filter
    
    class AnonymousDataFilter < Lanalytics::Filter::DataFilter

      DANGEROUS_KEYWORDS = %w(email name password)

      def filter(original_resource_as_hash, processed_resources, opts = nil)

        processed_resources.map! do | processed_resource |
          next unless processed_resource.is_a? Lanalytics::Model::StmtResource

          processed_resource.properties.delete_if { |key, value| symbol_anonymous?(key) }
          processed_resource
        end
      end


      private
      def symbol_anonymous?(symbol)
        DANGEROUS_KEYWORDS.each do | dangerous_keyword |
          return if symbol.to_s.include?(dangerous_keyword)
        end
      end
    end
  
  end
end
