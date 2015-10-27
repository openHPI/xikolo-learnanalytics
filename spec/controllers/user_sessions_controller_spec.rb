require 'rails_helper'

RSpec.describe UserSessionsController, type: :controller do

  describe "GET new" do
    it "returns http success" do
      get :new
      expect(response).to be_success
    end
  end

  describe "GET create" do
    it "returns http success" do
      get :create
      expect(response).to be_success
    end
  end

  describe "GET destroy", pending: true do
    it "returns http success" do
      get :destroy
      expect(response).to be_success
    end
  end

end
