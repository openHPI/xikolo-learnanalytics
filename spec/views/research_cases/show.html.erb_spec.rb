require 'rails_helper'

RSpec.describe "research_cases/show", :type => :view, pending: true do
  before(:each) do
    @research_case = assign(:research_case, ResearchCase.create!(
      :title => "Title"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
  end
end
