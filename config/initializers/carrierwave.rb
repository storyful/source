# frozen_string_literal: true

if Rails.env.test?

  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end

  # FileUploader

  CarrierWave::Uploader::Base.descendants.each do |klass|
    next if klass.anonymous?
    klass.class_eval do
      def cache_dir
        Rails.root.join('spec', 'support', 'uploads', 'tmp')
      end

      def store_dir
        Rails.root.join('spec', 'support', 'uploads', model.class.to_s.underscore, mounted_as, model.id)
      end
    end
  end
else
  CarrierWave.configure do |config|
    config.storage                             = :gcloud
    config.gcloud_bucket                       = ENV['BUCKET_NAME']
    config.gcloud_bucket_is_public             = true
    config.gcloud_authenticated_url_expiration = 600
    config.gcloud_content_disposition          = 'file'

    config.gcloud_attributes = {
      expires: 600
    }

    config.gcloud_credentials = {
      gcloud_project: ENV['PROJECT_ID'],
      gcloud_keyfile: ENV['GOOGLE_APPLICATION_CREDENTIALS']
    }
  end
end

CarrierWave.configure do |config|
  config.asset_host = ActionController::Base.asset_host
end
