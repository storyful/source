# frozen_string_literal: true

class Search
  include Redis::Objects
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :uid, :uploaded_image, :uploaded_image_id
  value :image_url
  value :image_path
  value :uploaded_image_uid
  value :results
  value :extracted_text
  value :created_at
  value :full_results

  validates :uploaded_image, presence: true

  def id
    @id ||= loop do
      token = SecureRandom.urlsafe_base64
      break token if UploadedImage.redis.keys("search:#{token}:*").empty?
    end
  end

  def self.create(uploaded_image, uploaded_image_id)
    search = Search.new
    search.uploaded_image_uid = uploaded_image_id
    search.image_url = uploaded_image.cropped_url
    search.image_path = uploaded_image.cropped_path
    search.uid = search.id

    search
  end

  def self.find(cache_id)
    image_url = Redis.current.get("search:#{cache_id}:image_url")
    image_id = Redis.current.get("search:#{cache_id}:uploaded_image_uid")
    return nil if image_url.nil?

    search = Search.new
    search.uid = cache_id
    search.uploaded_image = image_url
    search.uploaded_image_id = image_id
    search
  end

  def store_results(search_results, extracted_text)
    @results = Redis::Value.new("search:#{uid}:results")
    @results.value = search_results.to_json

    @text = Redis::Value.new("search:#{uid}:extracted_text")
    @text.value = extracted_text

    @created_at = Redis::Value.new("search:#{uid}:created_at")
    @created_at.value = Time.zone.today.strftime('%Y-%m-%d %H:%M')
  end
end
