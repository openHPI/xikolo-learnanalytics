class Course::SectionProgressPresenter < SectionPresenter
  def available?
    @section.available
  end

  def parent?
    @section.parent
  end

  def self_test_stats
    exercise_stats_for @section.selftest_exercises
  end

  def main_exercise_stats
    exercise_stats_for @section.main_exercises
  end

  def bonus_exercise_stats
    exercise_stats_for @section.bonus_exercises
  end

  def description
    @section.description
  end

  def items
    @section.items.map do |i|
      ItemPresenter.new item: Xikolo::Course::Item.new(i), course: @course
    end
  end

  def visits_stats
    Course::ProgressVisitsStatsPresenter.new @section.visits
  end

  def alternatives
    @section.attributes[:alternatives] #TODO: direct access fails
  end

  private
  def exercise_stats_for(stats)
    stats = {course: @course}.merge (stats || {})
    Course::ProgressExerciseStatsPresenter.new stats
  end
end
