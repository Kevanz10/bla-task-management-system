require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:tasks).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid").for(:email) }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
  end

  describe "password" do
    it "hashes the password" do
      user = create(:user, password: "password123")
      expect(user.password_digest).not_to eq("password123")
      expect(user.authenticate("password123")).to be_truthy
      expect(user.authenticate("wrong")).to be_falsey
    end
  end
end
