# frozen_string_literal: true

require 'redis-objects'
require 'open-uri'

class UploadedImage
  extend CarrierWave::Mount
  include Redis::Objects
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  mount_uploader :file, FileUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h, :scale_x, :scale_y, :rotate, :cropped_url, :cropped_path, :uid, :file_url, :file_path, :file_upload_width, :file_upload_height, :multiple_frames

  hash_key :fields

  validates :file, presence: true

  validates :file, file_size: { less_than: 2.megabytes },
                   file_content_type: { allow: ['image/jpeg', 'image/png', 'image/gif'] }

  validate :check_file_dimensions

  def check_file_dimensions
    errors.add :file, 'Invalid image. <br> The file must be a jpg, png or gif and must be less than 2mb.' if invalid_dimensions
  end

  def invalid_dimensions
    file_upload_width.nil? || file_upload_height.nil? || file_upload_width < 10 || file_upload_height < 10
  end

  def id
    @id ||= loop do
      token = SecureRandom.urlsafe_base64
      break token if UploadedImage.redis.keys("uploaded_image:#{token}:*").empty?
    end
  end

  def persisted?
    false
  end

  def self.create(params)
    u = UploadedImage.new
    u.file = params[:file]
    u.store_file!

    u.fields.bulk_set(params.merge(multiple_frames: Magick::ImageList.new(params[:file].path).length > 1, file_path: u.file.path, file_url: u.file.url, created_at: Time.zone.today.strftime('%Y-%m-%d %H:%M')))
    u.uid = u.id
    u
  end

  def self.find(cache_id)
    attrs = Redis::HashKey.new("uploaded_image:#{cache_id}:fields")

    return nil if attrs.all.keys.count.zero?

    uploaded_image = UploadedImage.new
    uploaded_image.uid = cache_id
    uploaded_image.file_url = attrs.all['file_url']
    uploaded_image.file_path = attrs.all['file_path']
    uploaded_image.multiple_frames = attrs.all['multiple_frames']
    uploaded_image
  end

  def self.update(uid, params)
    attrs = Redis::HashKey.new("uploaded_image:#{uid}:fields")
    store_in_cache(attrs, params)

    uploaded_image = model_from_cache(attrs)
    create_image_versions(uploaded_image, attrs)

    uploaded_image
  end

  def self.model_from_cache(attrs)
    uploaded_image = UploadedImage.new

    fields = %w[crop_x crop_y crop_w crop_h scale_x scale_y rotate file_path file_url]

    fields.each do |field|
      uploaded_image.send(:"#{field}=", attrs[field])
    end

    uploaded_image
  end

  def self.create_image_versions(uploaded_image, attrs)
    file = FileUploader.new.download_image_from_cloud(attrs['file_url'].to_s.split('/')[-1])

    uploaded_image.file = file
    uploaded_image.file.recreate_versions!(:cropped)

    attrs['cropped_url'] = uploaded_image.cropped_url = uploaded_image.file.cropped
    attrs['cropped_path'] = uploaded_image.cropped_path = uploaded_image.file.cropped.path
  end

  def self.store_in_cache(attrs, params)
    attrs['crop_x'] = params[:crop_x]
    attrs['crop_y'] = params[:crop_y]
    attrs['crop_w'] = params[:crop_w]
    attrs['crop_h'] = params[:crop_h]
    attrs['scale_x'] = params[:scale_x]
    attrs['scale_y'] = params[:scale_y]
    attrs['rotate'] = params[:rotate]
  end

  def self.cropped_path(host, file)
    Rails.env.development? ? host + file : file
  end

  def delete
    fields = Redis::HashKey.new("uploaded_image:#{uid}:fields")
    fields.clear
  end
end
