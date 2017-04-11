class SectionPresenter < PrivatePresenter
  def_delegators :@section, :id, :title,  :available?, :was_available?,
    :start_date, :end_date, :published?, :pinboard_closed?, :alternatives?,
    :section_choices?, :description, :section_choice?

  def items
    @section.items.map do |item|
      ItemPresenter.new item: item
    end
  end

  def to_param
    UUID4(id).to_s(format: :base62)
  end

  def alternatives
    return unless @section.alternatives?
    @section.alternatives.map do |alternative|
      SectionPresenter.new section: alternative
    end
  end

  def section_choices
    return unless @section.section_choices?
    @section.section_choices.map do |alternative|
      SectionPresenter.new section: alternative
    end
  end
end
