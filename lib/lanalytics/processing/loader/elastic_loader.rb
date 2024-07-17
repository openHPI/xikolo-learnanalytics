# frozen_string_literal: true

module Lanalytics
  module Processing
    module Loader
      class ElasticLoader < LoadStep
        def initialize(datasource = nil)
          super()

          @elastic_datasource = datasource
        end

        def load(original_event, load_commands, pipeline_ctx)
          load_commands.each do |load_command|
            command = load_command.class.name.demodulize.underscore
            entity = load_command.entity.class.name.demodulize.underscore

            method(:"do_#{command}_for_#{entity}").call(load_command)
          rescue StandardError => e
            Rails.logger.error do
              "Happened in pipeline '#{pipeline_ctx.pipeline.full_name}' for original_event: #{e.message}"
            end
            Rails.logger.error { original_event.inspect }
            Rails.logger.error { e.backtrace }
          end
        end

        def available?
          @elastic_datasource.ping
        end

        def do_create_command_for_entity(create_command)
          entity = create_command.entity

          indexing_hash = {}.tap do |hash|
            hash[:index] = @elastic_datasource.index
            hash[:type] = '_doc'
            hash[:id] = entity.primary_attribute.value.to_s if entity.primary_attribute
            hash[:body] = {}.tap do |body_hash|
              entity.all_non_nil_attributes.each do |attr|
                body_hash[attr.name.to_sym] = json_value_of(attr)
              end
            end
          end

          # Log what will be written to elastic search
          Rails.logger.debug { "[ELASTIC SEARCH WRITE] - #{indexing_hash}" }

          @elastic_datasource.exec do |client|
            client.index indexing_hash
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        def json_value_of(attribute)
          case attribute.data_type
            when :bool
              attribute.value.to_s.casecmp('true').zero? ? 'TRUE' : 'FALSE'
            when :string, :date, :timestamp, :uuid
              attribute.value.to_s
            when :int
              attribute.value.to_i
            when :float
              attribute.value.to_f
            when :entity
              {}.tap do |hash|
                attribute.value
                attribute.value.all_non_nil_attributes.each do |attr|
                  hash[attr.name.to_sym] = json_value_of(attr)
                end
              end
            else
              "'#{attribute.value}'"
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity
      end
    end
  end
end
