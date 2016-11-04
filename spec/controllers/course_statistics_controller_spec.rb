require 'spec_helper'

describe CourseStatisticsController do
  let(:default_params) { {format: 'json'}}
  let(:json) { JSON.parse response.body }
  let!(:course_id) {'00000001-3300-4444-9999-000000000006'}
  let(:course_id2) {'00000001-3300-4444-9999-000000000007'}
  let(:course_id3) {'00000001-3300-4444-9999-000000000008'}

  before do
    Acfs::Stub.resource Xikolo::Course::Course, :read,
                        with: { id: course_id},
                        return:
                            { id: course_id, title: 'Software Profiling Future' }
    Acfs::Stub.resource Xikolo::Course::Course, :read,
                        with: { id: course_id2},
                        return:
                            { id: course_id2, title: 'Course in Preparation', status: 'in preparation' }

    Acfs::Stub.resource Xikolo::Course::Course, :read,
                        with: { id: course_id3},
                        return:
                            { id: course_id3, title: 'SAP Course', affiliated: true , status: 'active' }

    Acfs::Stub.resource Xikolo::Course::Statistic, :read,
                        with: { course_id: course_id },
                        return: {
                            enrollments: 100,
                            last_day_enrollments: 10
                        }
    Acfs::Stub.resource Xikolo::Course::Statistic, :read,
                        with: { course_id: course_id2 },
                        return: {
                            enrollments: 100,
                            last_day_enrollments: 10
                        }

    Acfs::Stub.resource Xikolo::Course::Statistic, :read,
                        with: { course_id: course_id3 },
                        return: {
                            enrollments: 200,
                            last_day_enrollments: 20
                        }

    Acfs::Stub.resource Xikolo::Helpdesk::Statistic, :read,
                        with: { course_id: course_id },
                        return: {
                            ticket_count: 100,
                            ticket_count_last_day: 10
                        },legacy: true

    Acfs::Stub.resource Xikolo::Helpdesk::Statistic, :read,
                        with: { course_id: course_id2 },
                        return: {
                            ticket_count: 1000,
                            ticket_count_last_day: 100
                        },legacy: true

    Acfs::Stub.resource Xikolo::Helpdesk::Statistic, :read,
                        with: { course_id: course_id3 },
                        return: {
                            ticket_count: 1000,
                            ticket_count_last_day: 100
                        },legacy: true

    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id, key: 'extended' },
                        return: {
                            course_id: course_id,
                            user_id: nil,
                            student_enrollments: 5,
                            student_enrollments_by_day: nil,
                            student_enrollments_at_start: 0,
                            student_enrollments_at_middle: 1,
                            student_enrollments_at_middle_netto: 5,
                            shows: 1,
                            no_shows: 4,
                            certificates_count: 0,
                            new_users: 1
                            }

    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id2, key: 'extended' },
                        return: {
                            course_id: course_id2,
                            user_id: nil,
                            student_enrollments: 5,
                            student_enrollments_by_day: nil,
                            student_enrollments_at_start: 0,
                            student_enrollments_at_middle: 1,
                            student_enrollments_at_middle_netto: 1,
                            shows: 1,
                            no_shows: 4,
                            certificates_count: 0,
                            new_users: 1
                        }
    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id3, key: 'extended' },
                        return: {
                            course_id: course_id3,
                            user_id: nil,
                            student_enrollments: 25,
                            student_enrollments_by_day: nil,
                            student_enrollments_at_start: 0,
                            student_enrollments_at_middle: 1,
                            student_enrollments_at_middle_netto: 5,
                            shows: 5,
                            no_shows: 4,
                            certificates_count: 10,
                            new_users: 1
                        }

    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id, key: 'enrollments_by_day' },
                        return: { course_id: course_id,
                                  student_enrollments_by_day: { DateTime.now.iso8601.to_s => 199} }

    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id2, key: 'enrollments_by_day' },
                        return: { student_enrollments_by_day: { DateTime.now.iso8601.to_s => 199} }

    Acfs::Stub.resource Xikolo::Course::Stat, :read,
                        with: { course_id: course_id3, key: 'enrollments_by_day' },
                        return: { student_enrollments_by_day: { DateTime.now.iso8601.to_s => 199} }

    Acfs::Stub.resource Xikolo::Account::Statistic, :read,
                        with: { },
                        return: {
                            confirmed_users: 500,
                            confirmed_users_last_day: 50
                        }

    Acfs::Stub.resource Xikolo::Pinboard::Statistic, :read,
                        with: { },
                        return: {
                            questions: 500,
                            questions_last_day: 50
                        }
  end
  describe '#index' do
    it 'should answer with an empty list' do
      get :index
      expect(response.status).to eq(200)
      expect(json).to have(0).item
    end
  end

  describe '#show' do
    it 'should create a new course_statistic' do
      coursestatistics = CourseStatistic.all
      expect(coursestatistics.count).to eq(0)
      get :show, id: course_id
      expect(response.status).to eq(200)
      coursestatistics = CourseStatistic.all
      expect(coursestatistics.count).to eq(1)
    end

    it ' should update an course statistic' do
      cs = CourseStatistic.new(course_id: course_id2, course_name: 'Test Course')
      expect(cs.course_name).to eq 'Test Course'
      get :show, id: course_id2
      expect(json["course_name"]).to eq('Course in Preparation')
    end

    it 'should use the right values' do
      get :show, id: course_id3
      expect(json['course_id']).to eq course_id3
      expect(json['course_name']).to eq 'SAP Course'
      expect(json['course_status']).to eq 'active'
      expect(json['no_shows']).to eq 4.0
      expect(json['total_enrollments']).to eq 200
      expect(json['enrollments_last_day']).to eq 20
      expect(json['enrollments_at_course_start']).to eq 0
      expect(json['enrollments_at_course_middle_netto']).to eq 1
      expect(json['total_questions']).to eq 500
      expect(json['questions_last_day']).to eq 50
      expect(json['enrollments_per_day']).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 199]
    end
  end
end
