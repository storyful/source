# frozen_string_literal: true

class PageScraperService
  attr_reader :pages

  def initialize(pages)
    @pages = pages
  end

  def scrape
    hydra = Typhoeus::Hydra.new

    requests = @pages.map do |page|
      req = Typhoeus::Request.new(URI.parse(page['url']), followlocation: true, timeout: 4)
      hydra.queue(req)

      { page: page, request: req }
    end

    hydra.run

    to_hash(requests)
  end

  private

  def to_hash(requests)
    responses = {}

    requests.each do |item|
      next unless item[:request].response.code == 200
      responses[item[:page]['url']] = { page: item[:page], body: Nokogiri::HTML(item[:request].response.body) }
    end

    responses
  end
end
