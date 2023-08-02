# frozen_string_literal: true

class ImageProcessorService
  attr_reader :image

  def initialize(image)
    raise ArgumentError unless valid_image?(image)

    @image = image.is_a?(File) ? to_magick_image(image.path) : image
  end

  def crop(crop_params)
    raise ArgumentError if invalid_crop_params?(crop_params)

    @image.crop!(
      crop_params[:crop_x].to_i,
      crop_params[:crop_y].to_i,
      crop_params[:crop_w].to_i,
      crop_params[:crop_h].to_i
    )

    @image
  end

  def flip_x
    @image.flop!
  end

  def flip_y
    @image.flip!
  end

  def rotate(degree = 0)
    @image.rotate!(degree.to_f)
  end

  private

  def valid_image?(image)
    (image.is_a? File) || (image.is_a? Magick::Image)
  end

  def to_magick_image(path)
    Magick::Image.read(path).first
  end

  def invalid_crop_params?(crop_params)
    return true if crop_params.nil?
    return true if crop_params.keys.sort != %i[crop_x crop_y crop_w crop_h].sort

    false
  end
end
