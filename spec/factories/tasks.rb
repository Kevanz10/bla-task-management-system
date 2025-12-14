FactoryBot.define do
  factory :task do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { "pending" }
    due_date { 7.days.from_now.to_date }
  end
end
