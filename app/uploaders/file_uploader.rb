# frozen_string_literal: true

require 'google/cloud/storage'

class FileUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  TEMP_FOLDER = 'tmp'

  storage :gcloud

  process :remove_animation

  version :cropped, if: :to_crop? do
    process :process_image

    def filename(for_file = model.file.file)
      for_file.original_filename
    end
  end

  def to_crop?(_file)
    model.crop_x.present?
  end

  def process_image
    manipulate! do |img|
      apply_filters(img)
    end
  end

  def apply_filters(img)
    service = ImageProcessorService.new(img)

    service.flip_x if model.scale_x.to_i == -1
    service.flip_y if model.scale_y.to_i == -1
    service.rotate(model.rotate) if model.rotate.to_i.positive?

    service.crop(crop_params) if model.crop_x.present?
    service.image
  end

  def remove_animation
    manipulate! { |image, index| index.zero? ? image : nil } if content_type == 'image/gif'
  end

  def download_image_from_cloud(original_filename)
    storage = Google::Cloud::Storage.new
    bucket = storage.bucket ENV['BUCKET_NAME']

    file = bucket.file ENV['BUCKET_FOLDER'] + '/' + original_filename

    tmp_folder = Rails.root.join(TEMP_FOLDER, ENV['BUCKET_FOLDER'])
    Dir.mkdir(tmp_folder) unless File.exist?(tmp_folder)
    clone_name = Rails.root.join(TEMP_FOLDER, file.name).to_s

    file.download clone_name

    img = File.open(clone_name)
    File.delete(clone_name) if File.exist?(clone_name)
    img
  end

  def crop_params
    {
      crop_x: model.crop_x.to_i,
      crop_y: model.crop_y.to_i,
      crop_w: model.crop_w.to_i,
      crop_h: model.crop_h.to_i
    }
  end

  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  def filename
    "#{secure_token}.#{model.file.file.extension}" if original_filename
  end

  def size_range
    1..3.megabytes
  end

  before :cache, :capture_size_before_cache # callback, example here: http://goo.gl/9VGHI
  def capture_size_before_cache(new_file)
    model.file_upload_width, model.file_upload_height = `identify -format "%wx %h" #{new_file.path}`.split(/x/).map(&:to_i) if model.file_upload_width.nil? || model.file_upload_height.nil?
  end

  def store_dir
    ENV['BUCKET_FOLDER'] || 'uploads-dev'
  end

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end
