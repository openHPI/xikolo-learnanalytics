# Creates an deactivated Rule for each new worker
# Add those you want to see in production here

qc_rules = [
    ['LowCourseCommunicationWorker', false],
    ['PinboardActivityWorker', false],
    ['PinboardClosedForCoursesWorker', false],
    ['SlidesForAllCourseVideosWorker', false],
    ['TooLongVideosWorker', false],
    ['NoShowWorker', false],
    ['InitialAnnouncementWorker', false],
    ['VideoEventsWorker', false],
    ['AnnouncementFailedWorker', true],
    ['DifficultSelftestWorker', true]
]
#This will create an disabled (inactive) worker for each rule that is not set up yet
begin
  qc_rules.each do |worker, flag|
    rule = QcRule.find_or_initialize_by(worker:worker)
    if rule.new_record?
      rule.is_active = false
      rule.is_global = flag
      rule.save
    end
  end
rescue
  #db might not be there ins ome case (dev, old system, ...)
end
