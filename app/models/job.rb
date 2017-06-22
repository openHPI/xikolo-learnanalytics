class Job < ActiveRecord::Base
  validates_presence_of :user_id, :task_scope

  REPORT_CLASSES = {
    'course_export' => Reports::CourseReport,
    'user_info_export' => Reports::UserInfoReport,
    'submission_export' => Reports::SubmissionReport,
    'pinboard_export' => Reports::PinboardReport,
    'metric_export' => Reports::MetricReport,
    'course_events_export' => Reports::CourseEventsReport,
    'combined_course_export' => Reports::CombinedCourseReport,
  }

  default_scope {order('updated_at DESC')}

  class << self
    def start(job_id)
      Job.update job_id, status: 'started'
    end
  end

  def schedule(report_params)
    CreateReportJob.perform_later(id, report_params)
  end

  def generate!(params)
    REPORT_CLASSES.fetch(task_type).new(self, params).tap { |report|
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
  def fail
    update status: 'failing'
  end

  def tmp_directory
    Xikolo.config.data_dir.join('tmp', id)
  end

  def in_tmp_directory
    FileUtils.mkpath tmp_directory
    yield tmp_directory
  ensure
    FileUtils.rmtree tmp_directory
  end

  private

  def notify
    event = {
      key: 'reporting_finished',
      receiver_id: user_id,
      payload: {
        type: task_type,
        annotation: annotation,
        state: status
      }
    }
    Msgr.publish(event, to: 'xikolo.notification.platform_notify')
  end
end