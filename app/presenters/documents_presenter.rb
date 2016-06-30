class DocumentsPresenter < Presenter
  attr_accessor :enrollment, :course

  def self.create enrollment
    new(enrollment: enrollment).tap { |presenter| presenter.course! }
  end

  def course!
    @course = Xikolo::Course::Course.find enrollment.course_id
  end

  def cop?
    enrollment.certificates[:confirmation_of_participation]
  end

  def roa?
    enrollment.certificates[:record_of_achievement]
  end
end