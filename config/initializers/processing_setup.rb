Lanalytics::Processing::AmqpProcessingManager.load_processing_definitions("#{Rails.root}/config/processing.yml")


# Lanalytics::Processing.instance.add_processing_for('xikolo.web.event.create',
#   [ Lanalytics::Filter::ExpApiStatementDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.create',
#   [ Lanalytics::Filter::CourseDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.update',
#   [ Lanalytics::Filter::CourseDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.course.course.destroy',
#   [ Lanalytics::Filter::CourseDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


# Lanalytics::Processing.instance.add_processing_for('xikolo.course.item.create',
#   [ Lanalytics::Filter::ItemDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


# Lanalytics::Processing.instance.add_processing_for('xikolo.learning_room.learning_room.create',
#   [ Lanalytics::Filter::LearningRoomDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.learning_room.learning_room.update',
#   [ Lanalytics::Filter::LearningRoomDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.learning_room.learning_room.destroy',
#   [ Lanalytics::Filter::LearningRoomDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


# Lanalytics::Processing.instance.add_processing_for('xikolo.learning_room.membership.create',
#   [ Lanalytics::Filter::MembershipDataFilter.new(:user_id, :learning_room_id, :JOINED) ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])

# Lanalytics::Processing.instance.add_processing_for('xikolo.learning_room.membership.destroy',
#   [ Lanalytics::Filter::MembershipDataFilter.new(:user_id, :learning_room_id, :UN_JOINED) ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])


# Lanalytics::Processing.instance.add_processing_for('xikolo.course.enrollment.create',
#   [ Lanalytics::Filter::EnrollmentDataFilter.new ],
#   [ Lanalytics::Processor::LoggerProcessor.new, Lanalytics::Processor::Neo4jProcessor.new ])
