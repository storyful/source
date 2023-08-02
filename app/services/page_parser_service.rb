# frozen_string_literal: true

class PageParserService
  attr_reader :body, :headers

  def initialize(body, headers)
    @body = body
    @headers = headers
  end

  def parse
    {
      page_desc: meta_description,
      page_title: meta_title,
      page_keywords: meta_keywords,
      page_date: meta_date
    }
  end

  def meta_description
    @body.css('meta[@name="description"]').first['content']
  rescue OpenURI::HTTPError
    ''
  rescue StandardError
    ''
  end

  def meta_title
    @body.css('title').text
  rescue OpenURI::HTTPError
    ''
  end

  def meta_keywords
    @body.css('meta[@name="keywords"]').first['content']
  rescue OpenURI::HTTPError
    ''
  rescue StandardError
    ''
  end

  def meta_date
    @body.at('meta[name="date"]')['content']
  rescue OpenURI::HTTPError
    ''
  rescue StandardError
    ''
  end

  def last_modified
    last_modified_header = @headers.nil? ? nil : @headers['last-modified']
    last_modified = last_modified_header.nil? ? '' : Date.parse(last_modified_header).to_time.to_i

    { last_modified: last_modified }
  end
end
