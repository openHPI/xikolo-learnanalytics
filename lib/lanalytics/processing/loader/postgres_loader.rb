# frozen_string_literal: true

module Lanalytics
  module Processing
    module Loader
      class PostgresLoader < LoadStep
        def initialize(datasource = nil)
          @postgres_datasource = datasource
        end

        def tableColumnValueFromEntity(entity)
          table  = entity.entity_key
          column = entity.primary_attribute.name
          value  = sql_value_of(entity.primary_attribute)

          [table, column, value]
        end

        def load(_original_event, load_commands, _pipeline_ctx)
          load_commands.each do |load_command|
            command = load_command.class.name.demodulize.underscore

            method("do_#{command}").call(load_command)
          end
        end

        def available?
          @postgres_datasource.ping
        end

        def do_create_command(create_command)
          entity  = create_command.entity

          table   = entity.entity_key
          columns = entity.all_attribute_names.join(', ')
          values  = entity.all_non_nil_attributes.map {|attr| sql_value_of(attr) }.join(', ')

          execute_sql(%Q{
            INSERT INTO #{table} (#{columns})
            VALUES (#{values});
          })
        end

        def do_merge_entity_command(merge_entity_command)
          entity = merge_entity_command.entity
          table, column, value = tableColumnValueFromEntity(entity)

          columns = entity.all_attribute_names.join(', ')
          values  = entity.all_non_nil_attributes.map {|attr| sql_value_of(attr) }.join(', ')

          set_statements = entity.all_non_nil_attributes.collect {|attr|
            attr.name.to_s + ' = ' + sql_value_of(attr)
          }.join(', ')

          execute_sql(%Q{
            WITH upsert as (
              UPDATE #{table}
              SET #{set_statements}
              WHERE #{column} = #{value}
              RETURNING #{column}
            )
            INSERT INTO #{table} (#{columns})
            SELECT #{values}
            WHERE NOT EXISTS (SELECT 1 FROM upsert);
          })
        end

        def do_update_command(update_command)
          entity = update_command.entity
          table, column, value = tableColumnValueFromEntity(entity)

          set_statements = entity.all_non_nil_attributes.collect {|attr|
            attr.name.to_s + ' = ' + sql_value_of(attr)
          }.join(', ')

          execute_sql(%Q{
            UPDATE #{table}
            SET #{set_statements}
            WHERE #{column} = #{value}
          })
        end

        def do_destroy_command(destroy_command)
          entity = destroy_command.entity
          table, column, value = tableColumnValueFromEntity(entity)

          execute_sql(%Q{
            DELETE FROM #{table}
            WHERE #{column} = #{value}
          })
        end

        def do_custom_load_command(custom_load_command)
          return unless custom_load_command.loader_type.to_sym.downcase == :postgres

          execute_sql(custom_load_command.query)
        end

        def sql_value_of(attribute)
          case attribute.data_type
            when :string
              "'#{escape_string(attribute.value)}'"
            when :bool
              (attribute.value.to_s.downcase == 'true') ? 'TRUE' : 'FALSE'
            when :date, :timestamp, :uuid
              "'#{attribute.value}'"
            when :int, :float
              attribute.value.to_s
            when :json
              attribute.value.each do |key, val|
                attribute.value[key] = escape_string(val) if val.is_a? String
              end

              "'#{attribute.value.to_json}'"
            else
              "'#{attribute.value}'"
          end
        end

        def escape_string(str)
          PG::Connection.escape_string(
            str.delete("\x00"), # Ensure NULL bytes are stripped
          )
        end

        def execute_sql(sql)
          return if sql.nil? || sql.empty?

          # Log what will be written to postgres
          Rails.logger.debug { "[POSTGRES SQL EXEC] - #{sql}" }

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
