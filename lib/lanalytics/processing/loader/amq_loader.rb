module Lanalytics
  module Processing
    module Loader
      class AmqLoader < LoadStep

        def initialize(route)
          @route = route
        end

        def load(_original_event, load_commands, _pipeline_ctx)
          load_commands.each do |load_command|
            command = load_command.class.name.demodulize.underscore

            method("do_#{command}").call(load_command)
          end
        end

        def available?
          Msgr.client.running?
        end

        def do_create_command(create_command)
          message = create_command.entity.all_non_nil_attributes.map{ |attr| [attr.name, attr.value] }.to_h

          # Log what will be sent to AMQ
          Rails.logger.debug "[AMQ LOADER PUBLISH] - #{message} to route #{@route}"

          Msgr.publish message, to: @route
        end
      end
    end
  end
end