
# Msgr::Message.class_eval do

#   @@received_events = 0
#   # def received_events
#   #   return @@received_events
#   # end
#   # def increase_received_events(new_val)
#   #   return @@received_events
#   # end

#   @@total_time_until_events_reaches_msgr_gem = 0
#   # def self.total_time_until_events_reaches_msgr_gem
#   #   return @@total_time_until_events_reaches_msgr_gem
#   # end

#   def initialize(connection, delivery_info, metadata, payload, route)
#     @connection    = connection
#     @delivery_info = delivery_info
#     @metadata      = metadata
#     @payload       = payload
#     @route         = route

#     if content_type == 'application/json'
#       @payload = MultiJson.load(payload)
#       @payload.symbolize_keys! if @payload.respond_to? :symbolize_keys!
#     end

#     @@received_events += 1
#     @@total_time_until_events_reaches_msgr_gem += Time.now - Time.at(@payload[:creation_timestamp].to_f)
#     puts "========================"
#     puts "Event ##{@@received_events}: #{Time.now.to_f} - #{Time.at(@payload[:creation_timestamp].to_f).to_f}"
#     puts "Average Time until event reaches Msgr: #{@@total_time_until_events_reaches_msgr_gem/@@received_events}"
#   end

# end