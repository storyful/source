# frozen_string_literal: true

class ImageUrlScraperService
  attr_reader :url, :page, :cache, :hydra

  def initialize(url, page, cache, hydra)
    @url = url.split('?')[0]
    @page = page
    @hydra = hydra
    @cache = cache
  end

  def scrape
    req = Typhoeus::Request.new(URI.parse(@url), followlocation: true, timeout: 6)

    req.on_complete do |res|
      add_to_cache(res.headers) unless parsed_last_modified(res.headers['last-modified']).nil?
    end

    @hydra.queue(req)
  end

  private

  def add_to_cache(headers)
    @cache << page.merge(image_url: @url, last_modified: headers['last-modified'])
  end

  def parsed_last_modified(last_modified)
    Time.strptime(last_modified, '%a, %d %b %Y %H:%M:%S')
  rescue StandardError
    nil
  end
end
