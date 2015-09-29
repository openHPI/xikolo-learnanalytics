module Lanalytics
  module Processing
    module Loader

      class ElasticSearchLoader < LoadStep

        def initialize(datasource = nil)
          @elastic_datasource = datasource
        end

        def load(original_event, load_commands, pipeline_ctx)

          load_commands.each do | load_command |
            begin
              self.method("do_#{load_command.class.name.demodulize.underscore}_for_#{load_command.entity.class.name.demodulize.underscore}").call(load_command)
            rescue StandardError => e
              Rails.logger.error(%Q{Happened in pipeline '#{pipeline_ctx.pipeline.full_name}' for original_event: #{e.message}
#{original_event.inspect}
              })
              Rails.logger.debug(e.backtrace)
            end
          end
        end

        def do_create_command_for_entity(create_command)
          entity = create_command.entity

          indexing_hash = {}.tap do | hash |
            hash[:index] = @elastic_datasource.index
            hash[:type] = entity.entity_key
            hash[:id] = entity.primary_attribute.value.to_s if entity.primary_attribute
            hash[:body] = {}.tap do | body_hash |
              entity.all_non_nil_attributes.each do | attr |
                body_hash[attr.name.to_sym] = json_value_of(attr)
              end
            end
          end

          # Log what will be written to elastic search
          Rails.logger.debug { indexing_hash }

          @elastic_datasource.exec do | client |
            client.index indexing_hash
          end
        end

        def json_value_of(attribute)
          return case attribute.data_type
            when :bool
              (attribute.value.to_s.downcase == 'true') ? 'TRUE' : 'FALSE'
            when :string, :date, :timestamp, :uuid
              attribute.value.to_s
            when :int
              attribute.value.to_i
            when :float
              attribute.value.to_f
            when :entity
              {}.tap do | hash |
                attribute.value
                attribute.value.all_non_nil_attributes.each do | attr |
                  hash[attr.name.to_sym] = json_value_of(attr)
                end
              end
            else
              "'#{attribute.value.to_s}'"
          end
        end
      end

    end
  end
end
