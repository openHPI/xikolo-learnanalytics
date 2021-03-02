# frozen_string_literal: true

module Lanalytics
  def self.telegraf
    @telegraf ||= ::Telegraf::Agent.new('udp://localhost:8094')
  end
end
