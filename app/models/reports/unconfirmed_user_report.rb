# frozen_string_literal: true

module Reports
  class UnconfirmedUserReport < Base
    class << self
      def form_data
        {
          type: :unconfirmed_user_report,
          name: I18n.t(:'reports.unconfirmed_user_report.name'),
          description: I18n.t(:'reports.unconfirmed_user_report.desc'),
          options: [
            {
              type: 'checkbox',
              name: :machine_headers,
              label: I18n.t(:'reports.shared_options.machine_headers'),
            },
            {
              type: 'text_field',
              name: :zip_password,
              label: I18n.t(:'reports.shared_options.zip_password'),
              options: {
                placeholder: I18n.t(:'reports.shared_options.zip_password_placeholder'),
                input_size: 'large',
              },
            },
          ],
        }
      end
    end

    def generate!
      csv_file 'UnconfirmedUserReport', headers, &method(:each_user)
    end

    private

    def headers
      [
        'User ID',
        'Full Name',
        'Email',
        'Created',
      ]
    end

    def each_user
      index = 0

      users_promise =
        Xikolo.paginate_with_retries(max_retries: 3, wait: 60.seconds) do
          account_service.rel(:users).get(
            confirmed: false, per_page: 500,
          )
        end

      users_promise.each_item do |user, page|
        values = [
          user['id'],
          escape_csv_string(user['full_name']),
          user['email'],
          user['created_at'].to_datetime.strftime('%Y-%m-%d'),
        ]

        yield values

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def account_service
      @account_service ||= Restify.new(:account).get.value!
    end
  end
end
