# frozen_string_literal: true

FactoryBot.define do
  factory :search do
    factory :search_with_uploaded_image do
      association :uploaded_image, factory: :uploaded_image, strategy: :build
    end
  end
end
