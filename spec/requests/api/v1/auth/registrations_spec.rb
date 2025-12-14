require "rails_helper"

RSpec.describe "POST /api/v1/auth/register", type: :request do
  let(:user_params) do
      {
        user: {
          email: "user@example.com",
          password: "password123"
        }
      }
    end

    context "with valid params" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/register", params: user_params
        }.to change(User, :count).by(1)
      end

      it "returns user and token" do
        post "/api/v1/auth/register", params: user_params

        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("user@example.com")
        expect(json["token"]).to be_present
      end
    end

    context "with invalid email" do
      it "returns validation errors" do
        user_params[:user][:email] = "invalid"
        post "/api/v1/auth/register", params: user_params

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "user@example.com") }

      it "returns validation errors" do
        post "/api/v1/auth/register", params: user_params

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "with short password" do
      it "returns validation errors" do
        user_params[:user][:password] = "short"
        post "/api/v1/auth/register", params: user_params

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
end
