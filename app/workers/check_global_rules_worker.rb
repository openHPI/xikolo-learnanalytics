class CheckGlobalRulesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    QcRule.active.global.each do |global_rule|
      global_rule.checker.run
    end
  end
end
