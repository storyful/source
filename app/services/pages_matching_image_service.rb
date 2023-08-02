# frozen_string_literal: true

class PagesMatchingImageService
  attr_reader :data
  attr_accessor :cache, :pages, :whitelisted_urls, :limit

  def initialize(data, cache, whitelisted_urls, limit = nil)
    raise ArgumentError unless cache.is_a?(Hash)

    @whitelisted_urls = whitelisted_urls
    @limit = limit
    @data = filter_by_verified_only(data)
    @cache = cache
    @pages = {}
  end

  def process
    @pages = PageScraperService.new(@data).scrape

    process_pages
  end

  private

  def filter_by_verified_only(data)
    return data if @limit.nil?

    filtered = filtered_data(data)

    filtered.count.zero? ? data[0..@limit] : filtered
  end

  def filtered_data(data)
    filtered = []
    data.each do |item|
      item = item
      filtered << item if verified_and_reachable?(item)
      break if filtered.count >= @limit
    end
    filtered
  end

  def parse_page(url, item)
    parsed = PageParserService.new(item[:body], {}).parse
    parsed[:page_title] = item[:page]['page_title']
    parsed.merge(page_url: url)
  end

  def process_full_match_images(data, parsed, hydra)
    data.each do |item|
      ImageUrlScraperService.new(item['url'], parsed, @cache[:full_matches], hydra).scrape
    end
  end

  def process_pages
    hydra = Typhoeus::Hydra.new
    count = 0
    @pages.each do |url, item|
      parsed = parse_page(url, item)

      process_full_match_images(item[:page].full_matching_images, parsed, hydra)
      process_partial_images(item[:page].partial_matching_images, parsed, hydra)
      count += item[:page].full_matching_images.count + item[:page].partial_matching_images.count

      break if @limit.present? && count >= @limit
    end

    hydra.run
  end

  def process_partial_images(data, parsed, hydra)
    data.each do |item|
      ImageUrlScraperService.new(item['url'], parsed, @cache[:partial_matches], hydra).scrape
    end
  end

  def reachable?(url)
    req = Typhoeus::Request.new(URI.parse(url), followlocation: true, timeout: 4)
    req.run
    response = req.response
    response.code == 200
  end

  def verified?(url)
    uri = URIParser.parse_with_scheme(url)
    @whitelisted_urls.include?(uri.host.gsub(/www\./, ''))
  end

  def verified_and_reachable?(item)
    verified?(item['url']) && reachable?(item['url'])
  end
end
