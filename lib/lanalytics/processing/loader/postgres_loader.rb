module Lanalytics
  module Processing
    module Loader
      class PostgresLoader < LoadStep
          
        def load(original_event, load_commands, pipeline_ctx)

          load_commands.each do | load_command |
            self.method("do_#{load_command.class.name.demodulize.underscore}").call(load_command)
          end

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
            SELECT #{entity.all_non_nil_attributes.map { |attr| sql_value_of(attr) }.join(', ')} WHERE NOT EXISTS (SELECT 1 FROM upsert);
          })
        end

        def sql_value_of(attribute)
          return case attribute.data_type
            when :string, :date, :uuid
              "'#{attribute.value.to_s}'"
            when :int, :float
              attribute.value.to_s
            end
        end

        def execute_sql(sql)
          return if sql.nil? or sql.empty?

          $postgres_connection.with do |conn|
            begin
              conn.exec(sql)
            rescue Exception => e
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
