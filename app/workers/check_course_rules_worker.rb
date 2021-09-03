# frozen_string_literal: true

class CheckCourseRulesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high, retry: false

  def perform(course_id)
    course = Restify.new(:course).get.value!.rel(:course).get(id: course_id).value!

    QcRule.active.not_global.each do |course_rule|
      course_rule.checker.run course
    end
  end
end
