# frozen_string_literal: true

require 'lanalytics'

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
    'enrollment_statistics_report' => Reports::EnrollmentStatisticsReport,
    'course_content_report' => Reports::CourseContentReport,
    'overall_course_summary_report' => Reports::OverallCourseSummaryReport,
    'openwho_course_report' => Reports::Openwho::CourseReport,
    'openwho_combined_course_report' => Reports::Openwho::CombinedCourseReport,
  }.freeze

  default_scope { order('updated_at DESC') }

  class << self
    def create(attributes = {}, &block)
      super(attributes.merge(status: 'requested'), &block)
    end

    def create_and_enqueue(params)
      ReportJob.create(params).tap {|job| job.schedule if job.valid? }
    end

    def queued(job_id)
      ReportJob.update(job_id, status: 'queued').tap do |report|
        Lanalytics.telegraf.write(
          'report_jobs',
          tags: {id: job_id, type: report.task_type},
          values: {user_id: report.user_id, status: 'queued'},
        )
      end
    end

    def start(job_id)
      ReportJob.update(job_id, status: 'started').tap do |report|
        Lanalytics.telegraf.write(
          'report_jobs',
          tags: {id: job_id, type: report.task_type},
          values: {user_id: report.user_id, status: 'started'},
        )
      end
    end

    ###
    # Where should reports store CSV files while building them?
    #
    # This should be set using the RUNTIME_DIRECTORY environment variable in
    # production, but will fall back to Rails' own tmp dir locally.
    #
    def tmp_root
      @tmp_root ||= begin
        Pathname.new ENV.fetch 'RUNTIME_DIRECTORY'
      rescue KeyError
        Rails.root.join('tmp')
      end
    end

    def queue_name(job_id)
      REPORT_CLASSES.fetch(ReportJob.find(job_id).task_type).queue_name
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

  def progress_to(part, of:)
    part = part.to_i
    of = of.to_i

    # Prevent division by zero
    return if of == 0

    percentage = ((part / of.to_f) * 100).to_i
    progress = [0, percentage, 100].sort[1]

    Lanalytics.telegraf.write(
      'report_jobs',
      tags: {id: id, type: task_type},
      values: {
        user_id: user_id,
        status: 'progress',
        part: part,
        of: of,
        percentage: percentage,
        progress: progress,
      },
    )

    Xikolo::Reconnect.on_stale_connection do
      update progress: progress
    end
  end

  # Mark a job as complete and set the given attributes
  def finish_with(attributes)
    Lanalytics.telegraf.write(
      'report_jobs',
      tags: {id: id, type: task_type},
      values: {user_id: user_id, status: 'done'},
    )

    Xikolo::Reconnect.on_stale_connection do
      update attributes.merge(
        status: 'done',
        progress: 100,
        options: options.except('zip_password'),
      )
    end

    self
  end

  # Mark a job as failed
  def fail_with(error)
    title = "#{error.class.name}: #{error.message}"
    trace = error.backtrace.join("\n")

    Lanalytics.telegraf.write(
      'report_jobs',
      tags: {id: id, type: task_type},
      values: {
        user_id: user_id,
        status: 'failing',
        error: title,
        env_path: ENV['PATH'],
        tmp_dir: tmp_directory.to_s,
      },
    )

    Xikolo::Reconnect.on_stale_connection do
      update(
        status: 'failing',
        error_text: "#{title}\n#{trace}",
      )
    end
  end

  def failing?
    status == 'failing'
  end

  def tmp_directory
    self.class.tmp_root.join(id)
  end

  def with_tmp_directory
    FileUtils.mkpath tmp_directory

    File.open(tmp_directory) do |file|
      # Acquire a shared lock on our temporary directory so that files within
      # are not unlinked by system cleanup scripts while they are still written
      # to by our long-running report generation zombie processes. Otherwise,
      # they could no longer be found / read when zipping them up.
      #
      # Reference: https://systemd.io/TEMPORARY_DIRECTORIES/
      file.flock File::LOCK_SH

      yield tmp_directory
    end
  ensure
    FileUtils.rmtree tmp_directory
  end

  def scoped?
    %w[
      user_report
      unconfirmed_user_report
      overall_course_summary_report
      enrollment_statistics_report
    ].exclude? task_type
  end
end
