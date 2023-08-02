# frozen_string_literal: true

class SearchService
  attr_reader :image_path, :whitelisted_urls, :annotator
  attr_accessor :response, :results

  def initialize(image_path, whitelisted_urls, limit = nil)
    @limit = limit
    @annotator = Google::Cloud::Vision::ImageAnnotator.new
    @image_path = image_path
    @whitelisted_urls = whitelisted_urls
    @results = {
      verified: [],
      full_matches: [],
      partial_matches: [],
      similar_images: []
    }
  end

  def perform_search
    @response = @annotator.web_detection(
      image:  @image_path,
      max_results: Settings.google.max_results
    )

    pages_with_matching_images

    extract_verified
    @results
  end

  def verified?(url)
    @whitelisted_urls.include?(URI.parse(url).host.gsub(/www\./, ''))
  end

  private

  def extract_verified
    imgs_to_delete = []
    @results[:full_matches].each_with_index do |result, index|
      if verified?(result[:page_url])
        @results[:verified] << result
        imgs_to_delete << result[:image_url]
      end
    end
    @results[:full_matches].delete_if { |h| imgs_to_delete.include?(h[:image_url]) }

    imgs_to_delete = []

    @results[:partial_matches].each_with_index do |result, index|
      if verified?(result[:page_url])
        @results[:verified] << result
        imgs_to_delete << result[:image_url]
      end
    end

    @results[:partial_matches].delete_if { |h| imgs_to_delete.include?(h[:image_url]) }
  end

  def pages_with_matching_images
    @response.responses.each do |response|
      PagesMatchingImageService.new(response.web_detection.pages_with_matching_images, @results, @whitelisted_urls, @limit).process #full and partial matches
    end
  end
end
