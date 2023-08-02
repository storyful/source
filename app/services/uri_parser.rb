# frozen_string_literal: true

module URIParser
  def self.parse_with_scheme(url)
    uri = URI.parse(url)
    return uri if %w[http https].include?(uri.scheme)

    URI.parse("http://#{url}")
  end
end
