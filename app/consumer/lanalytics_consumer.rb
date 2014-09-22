class LanalyticsConsumer < Msgr::Consumer

  def update

    puts "Ich bin hier, du Klappskind"
    puts "Was ist die Payload: #{payload.inspect}"
    puts "Ich bin hier, du Klappskind"

  end
end
