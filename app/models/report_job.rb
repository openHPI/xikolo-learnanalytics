# frozen_string_literal: true

class ReportJob < ApplicationRecord
  validates :user_id, presence: true
  validates :task_type, presence: true
  validates :task_scope, presence: {if: :scoped?}

  before_destroy :validate_not_running

  REPORT_CLASSES = {
    'course_report' => Reports::CourseReport,
    'combined_course_report' => Reports::CombinedCourseReport,
    'user_report' => Reports::UserReport,
    'unconfirmed_user_report' => Reports::UnconfirmedUserReport,
    'submission_report' => Reports::SubmissionReport,
    'pinboard_report' => Reports::PinboardReport,
    'course_events_report' => Reports::CourseEventsReport,
    'enrollment_report' => Reports::EnrollmentReport,
    'course_content_report' => Reports::CourseContentReport,
    'overall_course_summary_report' => Reports::OverallCourseSummaryReport,
    'openwho_course_report' => Reports::Openwho::CourseReport,
    'openwho_combined_course_report' => Reports::Openwho::CombinedCourseReport,
  }.freeze

  default_scope { order('updated_at DESC') }

  class << self
    def start(job_id)
      ReportJob.update job_id, status: 'started'
    end
  end

  def schedule
    CreateReportJob.perform_later(id)
  end

  def generate!
    REPORT_CLASSES.fetch(task_type).new(self).tap(&:generate!)
  end

  def validate_not_running
    raise ReportJobRunningError if status == 'started'
  end

  class ReportJobRunningError < StandardError
    def message
      'Cannot delete running job'
    end
  end

  # rubocop:disable Naming/UncommunicativeMethodParamName
  def progress_to(part, of:)
    # Prevent division by zero
    return if of == 0

    percentage = ((part / of.to_f) * 100).to_i

    update progress: [0, percentage, 100].sort[1]
  end
  # rubocop:enable all

  # Mark a job as complete and set the given attributes
  def finish_with(attributes)
    update attributes.merge(
      status: 'done',
      progress: 100,
      options: options.except('zip_password'),
    )

    self
  end

  # Mark a job as failed
  def fail_with(error_message)
    update(
      status: 'failing',
      error_text: error_message,
    )
  end

  def failing?
    status == 'failing'
  end

  def tmp_directory
    Rails.root.join('tmp', id)
  end

  def with_tmp_directory
    FileUtils.mkpath tmp_directory
    yield tmp_directory
    FileUtils.rmtree tmp_directory
  end

  def scoped?
    %w[
      user_report
      unconfirmed_user_report
      overall_course_summary_report
    ].exclude? task_type
  end
end
