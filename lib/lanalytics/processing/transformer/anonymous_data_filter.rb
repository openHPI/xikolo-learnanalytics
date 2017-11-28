module Lanalytics
  module Processing
    module Transformer
      class AnonymousDataFilter < TransformStep

        ANONYMIZE_IPV4_MASK = IPAddr.new '255.255.0.0'
        ANONYMIZE_IPV6_MASK = IPAddr.new 'ffff:ffff:ff00::'

        def initialize(anonymize_ip:)
          super()
          @anonymize_ip = anonymize_ip
        end

        def transform(_original_event, processing_units, _load_commands, _pipeline_ctx)
          processing_units.each do |processing_unit|
            processing_unit.data.delete_if { |key, _value| symbol_anonymous?(key) }

            if @anonymize_ip
              next if processing_unit[:in_context].nil? || processing_unit[:in_context][:user_ip].nil?
              processing_unit[:in_context][:user_ip] = anonymize_ip(processing_unit[:in_context][:user_ip])
            end
          end
        end

        private

        def symbol_anonymous?(symbol)
          symbol[/(mail)|(email)|(name)|(password)/].present?
        end

        def anonymize_ip(ip)
          ip = IPAddr.new ip
          if ip.ipv4?
            ip &= ANONYMIZE_IPV4_MASK
          elsif ip.ipv6?
            ip &= ANONYMIZE_IPV6_MASK
          end

          ip.to_s
        end

      end
    end
  end
end
