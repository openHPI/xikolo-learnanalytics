class ReportJob < ActiveRecord::Base
  validates_presence_of :user_id
  validates_presence_of :task_type
  validates_presence_of :task_scope, if: :scoped?

  REPORT_CLASSES = {
    'course_report' => Reports::CourseReport,
    'combined_course_report' => Reports::CombinedCourseReport,
    'user_report' => Reports::UserReport,
    'unconfirmed_user_report' => Reports::UnconfirmedUserReport,
    'submission_report' => Reports::SubmissionReport,
    'pinboard_report' => Reports::PinboardReport,
    'course_events_report' => Reports::CourseEventsReport,
    'enrollment_report' => Reports::EnrollmentReport,
  }

  default_scope {order('updated_at DESC')}

  class << self
    def start(job_id)
      ReportJob.update job_id, status: 'started'
    end
  end

  def schedule(options)
    CreateReportJob.perform_later(id, options)
  end

  def generate!(options)
    REPORT_CLASSES.fetch(task_type).new(self, options).tap { |report|
      report.generate!
    }
  end

  def progress_to(part, of:)
    # Prevent division by zero
    return if of == 0

    percentage = ((part / of.to_f) * 100).to_i

    update progress: [0, percentage, 100].sort[1]
  end

  # Mark a job as complete and set the given attributes
  def finish_with(attributes)
    update attributes.merge(
      status: 'done',
      progress: 100
    )

    notify
    self
  end

  # Mark a job as failed
  def fail_with(error_message)
    update(
      status: 'failing',
      error_text: error_message
    )
  end

  def failing?
    status == 'failing'
  end

  def tmp_directory
    Xikolo.config.data_dir.join('tmp', id)
  end

  def with_tmp_directory
    FileUtils.mkpath tmp_directory
    yield tmp_directory
  ensure
    FileUtils.rmtree tmp_directory
  end

  def scoped?
    task_type != 'user_report' && task_type != 'unconfirmed_user_report'
  end

  private

  def notify
    Xikolo.api(:notification).value!.rel(:events).post(
      key: 'reporting_finished',
      payload: {
        type: task_type,
        annotation: annotation,
        state: status
      },
      public: false,
      subscribers: [user_id]
    ).value!
  end
end