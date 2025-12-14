require "rails_helper"

RSpec.describe Task, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:task) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(1).is_at_most(255) }
  end

  describe "enum" do
    it "defines status enum with string values" do
      expect(described_class.statuses).to eq(
        "pending" => "pending",
        "in_progress" => "in_progress",
        "completed" => "completed"
      )
    end

    it "only accepts valid status values" do
      expect { build(:task, status: "invalid") }.to raise_error(ArgumentError)
    end
  end

  describe "scopes" do
    let!(:pending_task) { create(:task, status: "pending", due_date: 5.days.from_now) }
    let!(:completed_task) { create(:task, status: "completed", due_date: 10.days.from_now) }
    let!(:old_task) { create(:task, due_date: 5.days.ago) }

    describe ".by_status" do
      it "returns tasks with given status" do
        expect(described_class.by_status("pending")).to include(pending_task)
        expect(described_class.by_status("pending")).not_to include(completed_task)
      end
    end

    describe ".due_before" do
      it "returns tasks due before given date" do
        expect(described_class.due_before(1.day.from_now)).to include(old_task)
        expect(described_class.due_before(1.day.from_now)).not_to include(pending_task)
      end
    end

    describe ".due_after" do
      it "returns tasks due after given date" do
        expect(described_class.due_after(1.day.from_now)).to include(pending_task)
        expect(described_class.due_after(1.day.from_now)).not_to include(old_task)
      end
    end
  end
end
