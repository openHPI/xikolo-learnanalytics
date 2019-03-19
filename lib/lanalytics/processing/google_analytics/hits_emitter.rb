module Lanalytics
  module Processing
    module GoogleAnalytics
      class HitsEmitter
        include Singleton
  
        MAX_BATCH_SIZE = 10
        MAX_QUEUE_TIME = 1.hour
        BATCH_HITS_ENDPOINT = 'https://www.google-analytics.com/batch'
        DEBUG_HITS_ENDPOINT = 'https://www.google-analytics.com/debug/collect'
  
  
        def initialize(debug: nil)
          @debug = debug.nil? ? (not Rails.env.production?) : debug
          @conn = Faraday.new(:url => @debug ? DEBUG_HITS_ENDPOINT : BATCH_HITS_ENDPOINT)
        end
  
        def batching_queue
          @batching_queue ||= begin
            queue = BatchingQueue.new(max_batch_size: MAX_BATCH_SIZE, max_queue_time: MAX_QUEUE_TIME)
            queue.on_flush { |messages| flush messages }
            queue
          end
        end
  
        def emit(message)
          batching_queue.push(message)
        end
  
        def flush(messages)
          return unless messages.size > 0
  
          hits = messages.map do |message|
            hit = message.payload.deep_dup
            hit[:qt] = (Time.now - hit[:qt]).to_i
            hit
          end
  
          # Log how many hits are sent to Google Analytics
          Rails.logger.debug "[GOOGLE ANALYTICS FLUSH] - sent #{hits.size} hits"
  
          begin
            response = @conn.post do |req|
              req.body = hits.map(&:to_query).join("\r\n")
            end
          rescue Faraday::ConnectionFailed => e
            Rails.logger.error "[GOOGLE ANALYTICS REQUEST ERROR] - #{e.message}."
            messages.each(&:nack)
            return
          end
  
          # If debug is enabled, response contains validation results of sent hits
          if @debug
            validate_response response
          end
  
          messages.each(&:ack)
        end
  
        def validate_response(response)
          begin
            results = JSON.parse response.body
          rescue JSON::ParserError
            Rails.logger.error { "[GOOGLE ANALYTICS REQUEST ERROR] - API returned status code #{response.status}." }
            return
          end
  
          results['parserMessage'].select{ |msg| msg['messageType'] == 'ERROR' }
              .map{ |msg| msg['description'] }
              .each{ |err| Rails.logger.error "[GOOGLE ANALYTICS REQUEST ERROR] - #{err}" }
          results['hitParsingResult'].select{ |msg| !msg['valid'] }.each do |hit_result|
            errors = hit_result['parserMessage'].select{ |msg| msg['messageType'] == 'ERROR' }
                         .map{ |msg| msg['description'] }
            Rails.logger.error "[GOOGLE ANALYTICS HIT ERROR] - #{errors.join(' ')} (#{hit_result['hit']})"
          end
        end
      end
    end
  end
end