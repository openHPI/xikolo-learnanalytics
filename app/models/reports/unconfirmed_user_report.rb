module Reports
  class UnconfirmedUserReport < Base

    def initialize(job, options = {})
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
      Xikolo::Account::User.each_item(confirmed: false, per_page: 500) do |user, users|
        values = [
          user.id,
          user.first_name,
          user.last_name,
          user.email,
          user.created_at.strftime('%Y-%m-%d')
        ]

        yield values

        index += 1
        @job.progress_to(index, of: users.total_count)
      end

      Acfs.run
    end

  end
end
