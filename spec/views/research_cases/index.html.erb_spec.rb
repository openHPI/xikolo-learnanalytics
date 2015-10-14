require 'rails_helper'

RSpec.describe "research_cases/index", type: :view, pending: true do
  before(:each) do
    assign(:research_cases, [
      ResearchCase.create!(
        title: "Title"
      ),
      ResearchCase.create!(
        title: "Title"
      )
    ])
  end

  it "renders a list of research_cases", pending: true do
    render
    assert_select ".row>.panel", count: 2
  end
end
