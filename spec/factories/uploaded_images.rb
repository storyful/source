# frozen_string_literal: true

FactoryBot.define do
  skip_create

  factory :uploaded_image do
    uid { SecureRandom.urlsafe_base64(24).delete('-_').first(24) }

    file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'sample_100kb.jpg'), 'image/jpeg') }
    trait :valid_image do
      file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'sample_100kb.jpg'), 'image/jpeg') }
    end

    trait :large_image do
      file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'sample_5mb.jpg'), 'image/jpeg') }
    end

    trait :invalid_type do
      file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'image.txt'), 'text/plain') }
    end

    trait :invalid_dimensions do
      file { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'sample_invalid.jpeg'), 'image/jpeg') }
    end
  end
end
