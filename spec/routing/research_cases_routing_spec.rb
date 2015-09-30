require "rails_helper"

RSpec.describe ResearchCasesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(get: "/research_cases").to route_to("research_cases#index", format: 'html')
    end

    it "routes to #new" do
      expect(get: "/research_cases/new").to route_to("research_cases#new", format: 'html')
    end

    it "routes to #show" do
      expect(get: "/research_cases/1").to route_to("research_cases#show", id: "1", format: 'html')
    end

    it "routes to #edit" do
      expect(get: "/research_cases/1/edit").to route_to("research_cases#edit", id: "1", format: 'html')
    end

    it "routes to #create" do
      expect(post: "/research_cases").to route_to("research_cases#create", format: 'html')
    end

    it "routes to #update" do
      expect(put: "/research_cases/1").to route_to("research_cases#update", id: "1", format: 'html')
    end

    it "routes to #destroy" do
      expect(delete: "/research_cases/1").to route_to("research_cases#destroy", id: "1", format: 'html')
    end

  end
end
