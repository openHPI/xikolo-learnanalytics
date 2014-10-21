Lanalytics::Processing.instance.add_processing_for('xikolo.web.event.create',
  [ Lanalytics::Filter::ExpApiStatementDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.create',
  [ Lanalytics::Filter::CourseDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.update',
  [ Lanalytics::Filter::CourseDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.destroy',
  [ Lanalytics::Filter::CourseDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


Lanalytics::Processing.instance.add_processing_for('xikolo.course.item.create',
  [ Lanalytics::Filter::ItemDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


Lanalytics::Processing.instance.add_processing_for('xikolo.course.enrollment.create',
  [ Lanalytics::Filter::EnrollmentDataFilter.new ],
  [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])
