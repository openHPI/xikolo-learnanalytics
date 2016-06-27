class QcRunAllRules
  include Sidekiq::Worker
  sidekiq_options :queue => :high

  def perform
    global_rules = QcRule.where(is_active: true, is_global: true) #only actives ones
    global_rules.each do |global_rule|
      worker_class = Module.const_get global_rule.worker.camelize
      worker_class.new.perform(nil, global_rule.id)
    end
    rules = QcRule.where(is_active: true).where('is_global IS FALSE OR is_global IS NULL') #only actives ones
    #most will be called once per active course
    courses_pager = 1
    loop do
      courses = Xikolo::Course::Course.where(per_page: 50, page: courses_pager, affiliated: 'true', public: 'true')
      Acfs.run
      courses_pager += 1
      courses.each do |course|
        # we might want to run checks for external courses too later, so we fetch them
        unless course.external_course_url.present?
          rules.each do |rule|
            worker_class = Module.const_get rule.worker.camelize
            worker_class.new.perform(course, rule.id)
          end
        end
      end
      break if courses.total_pages.to_i == 0
      break if (courses.current_page.to_i >= courses.total_pages.to_i)
    end
  end
end