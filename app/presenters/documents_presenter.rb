class DocumentsPresenter < Presenter
  attr_accessor :enrollment

  def self.create(enrollment)
    new(enrollment: enrollment)
  end

  def cop?
    enrollment.certificates[:confirmation_of_participation]
  end

  def roa?
    enrollment.certificates[:record_of_achievement]
  end
end