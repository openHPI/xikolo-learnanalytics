module ProgressHelper
  def calc_progress(graded_points, total_points)
    unless total_points == 0
      (graded_points.fdiv(total_points) * 100).floor
    else
      total_points
    end
  end
end