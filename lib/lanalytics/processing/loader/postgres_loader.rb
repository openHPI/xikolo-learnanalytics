module Lanalytics
  module Processing
    module Loader
      class PostgresLoader < LoadStep

        def initialize(datasource = nil)
          @postgres_datasource = datasource
        end

        def load(_original_event, load_commands, _pipeline_ctx)
          load_commands.each do |load_command|
            method("do_#{load_command.class.name.demodulize.underscore}").call(load_command)
          end
        end

        def do_create_command(create_command)
          entity = create_command.entity

          execute_sql(%Q{
            INSERT INTO #{entity.entity_key} (#{entity.all_attribute_names.join(', ')})
            VALUES (#{entity.all_non_nil_attributes.map { |attr| sql_value_of(attr) }.join(', ')});
          })
        end

        def do_merge_entity_command(merge_entity_command)
          entity = merge_entity_command.entity

          execute_sql(%Q{
            WITH upsert as (
              UPDATE #{entity.entity_key}
              SET #{entity.all_non_nil_attributes.collect { | attr | attr.name.to_s + ' = ' + sql_value_of(attr)}.join(', ')}
              WHERE #{entity.primary_attribute.name} = #{sql_value_of(entity.primary_attribute)}
              RETURNING #{entity.primary_attribute.name}
            )
            INSERT INTO #{entity.entity_key} (#{entity.all_attribute_names.join(', ')})
            SELECT #{entity.all_non_nil_attributes.map { |attr| sql_value_of(attr) }.join(', ')}
            WHERE NOT EXISTS (SELECT 1 FROM upsert);
          })
        end

        def do_update_command(update_command)
          entity = update_command.entity

          execute_sql(%Q{
            UPDATE #{entity.entity_key}
            SET #{entity.all_non_nil_attributes.collect { | attr | attr.name.to_s + ' = ' + sql_value_of(attr)}.join(', ')}
            WHERE #{entity.primary_attribute.name} = #{sql_value_of(entity.primary_attribute)}
          })
        end

        def do_destroy_command(destroy_command)
          entity = destroy_command.entity

          execute_sql(%Q{
            DELETE FROM #{entity.entity_key}
            WHERE #{entity.primary_attribute.name} = #{sql_value_of(entity.primary_attribute)}
          })
        end

        def do_custom_load_command(custom_load_command)
          return unless custom_load_command.loader_type.to_sym.downcase == :postgres

          execute_sql(custom_load_command.query)
        end

        def sql_value_of(attribute)
          case attribute.data_type
          when :string
            "'#{PGconn.escape_string(attribute.value)}'"
          when :bool
            (attribute.value.to_s.downcase == 'true') ? 'TRUE' : 'FALSE'
          when :date, :timestamp, :uuid
            "'#{attribute.value}'"
          when :int, :float
            attribute.value.to_s
          else
            "'#{attribute.value}'"
          end
        end

        def execute_sql(sql)
          return if sql.nil? || sql.empty?

          @postgres_datasource.exec do |conn|
            # $postgres_connection.with do |conn|
            begin
              conn.exec(sql)
            rescue StandardError => e
              Rails.logger.error(%Q{
                Following error occurred when executing a SQL query on Postgres: #{e.message}
                #{sql}
              })
            end
          end
        end
      end
    end
  end
end
