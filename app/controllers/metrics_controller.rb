# frozen_string_literal: true

class MetricsController < ApplicationController
  skip_before_action :authenticate_user
  skip_before_action :verify_authenticity_token

  def index
    file = File.open(Rails.root.join('spec', 'support', 'sample_100kb.jpg'))
    uploaded_image = UploadedImage.create(file: file)

    SearchService.new(uploaded_image.fields['file_url'], [], 10).perform_search

    uploaded_image.delete

    count = Redis.current.keys('uploaded_image:*').count

    render status: :ok, json: { last: count }
  end
end
