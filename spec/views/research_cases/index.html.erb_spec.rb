require 'rails_helper'

RSpec.describe "research_cases/index", :type => :view do
  before(:each) do
    assign(:research_cases, [
      ResearchCase.create!(
        :title => "Title"
      ),
      ResearchCase.create!(
        :title => "Title"
      )
    ])
  end

  it "renders a list of research_cases" do
    render
    assert_select "tr>td", :text => "Title".to_s, :count => 2
  end
end
