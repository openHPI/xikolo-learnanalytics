require 'rails_helper'

RSpec.describe "research_cases/new", :type => :view do
  before(:each) do
    assign(:research_case, ResearchCase.new(
      :title => "MyString"
    ))
  end

  it "renders new research_case form" do
    render

    assert_select "form[action=?][method=?]", research_cases_path, "post" do

      assert_select "input#research_case_title[name=?]", "research_case[title]"
    end
  end
end
