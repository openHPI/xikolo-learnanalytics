# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
module Reports::Openwho
  class CourseReport < Reports::Base
    def initialize(job)
      super

      @deanonymized =
        job.options['deanonymized']
      @include_enrollment_evaluation =
        job.options['include_enrollment_evaluation']
    end

    def generate!
      @job.update(annotation: course['course_code'])

      csv_file(
        "OpenWHO_CourseReport_#{course['course_code']}",
        headers,
        &method(:each_row)
      )
    end

    private

    def headers
      @headers ||= [
        'User ID',
        'User Created',
        'Language',
        'Affiliated',
        'Age Group',
        'Primary Language',
        'Gender',
        'Affiliation',
        'Country of Nationality',
        'Last Country (Name)',
      ].tap do |headers|
        if reportable_country_regions.any?
          headers.append('Last Country (Region)')
        end

        if @include_enrollment_evaluation
          headers.append(
            'Items Visited',
            'Items Visited Percentage',
            'Points',
            'Points Percentage',
          )
        end

        headers.append('Course Code')
      end
    end

    def each_row
      courses.each_with_index do |course, course_index|
        index = 0

        enrollments_promise =
          Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
            course_service.rel(:enrollments).get(
              course_id: course['id'], per_page: 50, deleted: true,
            )
          end

        enrollments_promise.each_item do |enrollment, enrollment_page|
          user = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              account_service.rel(:user).get(id: enrollment['user_id'])
            end,
          ).value!.first

          profile = Xikolo::RetryingPromise.new(
            Xikolo::Retryable.new(max_retries: 5, wait: 90.seconds) do
              user.rel(:profile).get
            end,
          ).value!.first

          course_start_date = course['start_date']&.to_datetime
          birth_compare_date = course_start_date || Time.zone.now
          age =
            if user['born_at'].present?
              ((birth_compare_date - user['born_at'].to_datetime) / 365).to_i
            end

          profile_fields = ProfileFields.new(profile, @deanonymized)

          values = [
            @deanonymized ? user['id'] : Digest::SHA256.hexdigest(user['id']),
            user['created_at'],
            user['language'],
            user['affiliated'],
            age.present? ? age_group(age) : nil,
            profile_fields['primary_language'],
            profile_fields['gender'],
            profile_fields['affiliation'],
            profile_fields['country'],
          ]

          last_country_code = fetch_metric(
            'LastCountry', course['id'], user['id']
          ).dig(:code)
          last_country_name = suppress(IsoCountryCodes::UnknownCodeError) do
            IsoCountryCodes.find(last_country_code)&.name
          end

          values.append(last_country_name || last_country_code)

          if reportable_country_regions.any?
            regions = reportable_country_regions.select do |_, countries|
              countries.any? {|c| c.casecmp(last_country_code) == 0 }
            end

            values.append(regions.keys.join(';'))
          end

          if @include_enrollment_evaluation
            evaluation = Xikolo::RetryingPromise.new(
              Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
                course_service.rel(:enrollments).get(
                  course_id: course['id'],
                  user_id: enrollment['user_id'],
                  deleted: true,
                  learning_evaluation: true,
                )
              end,
            ).value!.first.first # destruct promise array and then response

            values.append(
              evaluation.dig('visits', 'visited'),
              evaluation.dig('visits', 'percentage'),
              evaluation.dig('points', 'achieved'),
              evaluation.dig('points', 'percentage'),
            )
          end

          values.append(course['course_code'])

          yield values

          index += 1
          @job.progress_to(
            (course_index *
              enrollment_page.response.headers['X_TOTAL_COUNT'].to_i) + index,
            of: courses.count *
              enrollment_page.response.headers['X_TOTAL_COUNT'].to_i,
          )
        end
      end
    end

    def age_group(age)
      case age.to_i
        when 0...20
          '<20'
        when 20...30
          '20-29'
        when 30...40
          '30-39'
        when 40...50
          '40-49'
        when 50...60
          '50-59'
        when 60...70
          '60-69'
        else
          '70+'
      end
    end

    def fetch_metric(metric, course_id, user_id)
      metric = "Lanalytics::Metric::#{metric}".constantize
      metric.query(user_id: user_id, course_id: course_id)
    end

    def reportable_country_regions
      Xikolo.config.reports['country_regions'] || {}
    end

    def courses
      # return an array with the course
      @courses ||= Xikolo::RetryingPromise.new(
        Xikolo::Retryable.new(max_retries: 3, wait: 60.seconds) do
          course_service.rel(:course).get(id: @job.task_scope)
        end,
      ).value!
    end

    def course
      courses.first
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

    def course_service
      @course_service ||= Xikolo.api(:course).value!
    end
  end
end
# rubocop:enable all
