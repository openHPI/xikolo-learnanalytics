# frozen_string_literal: true

class CheckGlobalRulesWorker
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: false

  def perform
    QcRule.active.global.each do |global_rule|
      global_rule.checker.run
    end
  end
end
