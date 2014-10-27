require 'rails_helper'

RSpec.describe "ResearchCases", :type => :request do
  describe "GET /research_cases" do
    it "works! (now write some real specs)" do
      get research_cases_path
      expect(response.status).to be(200)
    end
  end
end
