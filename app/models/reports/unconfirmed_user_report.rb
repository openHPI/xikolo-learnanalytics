module Reports
  class UnconfirmedUserReport < Base

    def initialize(job)
      super
    end

    def generate!
      csv_file 'UnconfirmedUserReport', headers, &method(:each_user)
    end

    private

    def headers
      [
        'User ID',
        'First Name',
        'Last Name',
        'Email',
        'Created'
      ]
    end

    def each_user
      index = 0

      Xikolo.paginate(
        account_service.rel(:users).get(
          confirmed: false, per_page: 500
        )
      ) do |user, page|
        values = [
          user['id'],
          escape_csv_string(user['first_name']),
          escape_csv_string(user['last_name']),
          user['email'],
          user['created_at'].to_datetime.strftime('%Y-%m-%d')
        ]

        yield values

        index += 1
        @job.progress_to(index, of: page.response.headers['X_TOTAL_COUNT'])
      end
    end

    def account_service
      @account_service ||= Xikolo.api(:account).value!
    end

  end
end
