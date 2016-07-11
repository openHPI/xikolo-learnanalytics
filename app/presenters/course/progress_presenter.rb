class Course::ProgressPresenter < CourseInfoPresenter
  def self.build(user, course)
    new({
      course: course,
      user: user,
      progresses: Xikolo::Course::Progress.where(user_id: user.id,
                                                 course_id: course.id)
    }).tap do |presenter|
      presenter.enrollment!
    end
  end

  def initialize(*args)
    super
    Acfs.on @progresses do |progresses|
      @course_progress = progresses.pop
      @section_progresses = progresses
    end
  end

  def enrollment!
    Xikolo::Course::Enrollment.find_by(user_id: @user.id, course_id: @course.id, learning_evaluation: true) do |enrollment|
      @documents = DocumentsPresenter.create(enrollment)
    end
  end

  def cop?
    @documents.cop?
  end

  def roa?
    @documents.roa?
  end


  def available?
    @course_progress.visits.fetch(:total, 0) > 0
  end

  def with_bonus_exercises?
    !@course_progress.bonus_exercises.nil?
  end

  def sections
    @section_progresses.map do |section|
      Course::SectionProgressPresenter.new section: section, course: @course
    end
  end

  # self test stats:
  def self_test_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.selftest_exercises
  end

  # main exercises stats:
  def main_exercise_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.main_exercises
  end

  # bonus exercises stats:
  def bonus_exercise_stats
    Course::ProgressExerciseStatsPresenter.new @course_progress.bonus_exercises
  end

  def visits_stats
    Course::ProgressVisitsStatsPresenter.new @course_progress.visits
  end
end
