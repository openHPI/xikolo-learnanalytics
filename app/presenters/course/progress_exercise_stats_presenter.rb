class Course::ProgressExerciseStatsPresenter < PrivatePresenter
  include ProgressHelper

  def available?
    @total_exercises and @total_exercises > 0
  end

  attr_reader :total_exercises, :submitted_exercises, :graded_exercises
  attr_reader :next_publication_date, :last_publication_date

  def total_points
    @max_points.round(2)
  end

  def submitted_points
    @submitted_points.round(2)
  end

  def graded_points
    @graded_points.round(2)
  end

  def my_progress
    calc_progress(graded_points, total_points)
  end

  def withhold_gradings?
    @submitted_exercises != @graded_exercises
  end

  def items
    (@items || []).map do |i|
      ItemPresenter.new item: Xikolo::Course::Item.new(i), course: @course
    end
  end
end
