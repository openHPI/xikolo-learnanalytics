require 'rails_helper'

RSpec.describe "research_cases/edit", type: :view, pending: true do
  before(:each) do
    @research_case = assign(:research_case, ResearchCase.create!(
      title: "MyString"
    ))
  end

  it "renders the edit research_case form" do
    render

    assert_select "form[action=?][method=?]", research_case_path(@research_case), "post" do

      assert_select "input#research_case_title[name=?]", "research_case[title]"
    end
  end
end
