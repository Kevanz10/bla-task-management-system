require "rails_helper"

RSpec.describe "POST /api/v1/auth/login", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }
  let(:login_params) do
    {
      user: {
        email: "user@example.com",
        password: "password123"
      }
    }
  end

  context "with valid credentials" do
    it "returns user and token" do
      post "/api/v1/auth/login", params: login_params

      json = JSON.parse(response.body)
      expect(json["user"]["email"]).to eq("user@example.com")
      expect(json["token"]).to be_present
    end
  end

  context "with invalid email" do
    it "returns unauthorized error" do
      login_params[:user][:email] = "wrong@example.com"
      post "/api/v1/auth/login", params: login_params

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
      expect(json["errors"].first["detail"]).to eq("Invalid email or password")
    end
  end

  context "with invalid password" do
    it "returns unauthorized error" do
      login_params[:user][:password] = "wrongpassword"
      post "/api/v1/auth/login", params: login_params

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
      expect(json["errors"].first["detail"]).to eq("Invalid email or password")
    end
  end
end
