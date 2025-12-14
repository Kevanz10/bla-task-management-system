class Task < ApplicationRecord
  belongs_to :user

  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed"
  }

  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :status, inclusion: { in: statuses.keys }

  scope :by_status, ->(status) { where(status: status) if statuses.key?(status) }
  scope :due_before, ->(date) { where("due_date < ?", date) }
  scope :due_after, ->(date) { where("due_date > ?", date) }
end
