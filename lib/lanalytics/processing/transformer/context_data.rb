module Lanalytics
  module Processing
    module Transformer
      class ContextData < TransformStep
        def transform(original_event, processing_units, load_commands, pipeline_ctx)
          processing_units.each do |processing_unit|
            next if processing_unit[:in_context].nil? || processing_unit[:in_context][:user_agent].nil?

            user_agent = processing_unit[:in_context][:user_agent]

            browser = Browser.new(user_agent)

            processing_unit[:in_context][:platform]         = safe_read { browser.platform.name }     || "Unknown"
            processing_unit[:in_context][:platform_version] = safe_read { browser.platform.version }  || "0"
            processing_unit[:in_context][:runtime]          = safe_read { browser.name }              || "Unknown"
            processing_unit[:in_context][:runtime_version]  = safe_read { browser.version }           || "0"
            processing_unit[:in_context][:device]           = safe_read { browser.device.name }       || "Unknown"

            # merge platfrom 'iOS (iPhone)', 'iOS (iPad)' and 'iOS (iPod)' to 'iOS'
            processing_unit[:in_context][:platform]         =
              "iOS" if processing_unit[:in_context][:platform].start_with? "iOS"
          end
        end

        private

        def safe_read(&block)
          yield
        rescue
          nil
        end
      end
    end
  end
end
