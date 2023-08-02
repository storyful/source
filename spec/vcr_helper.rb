# frozen_string_literal: true

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  config.configure_rspec_metadata!

  record_cassettes = ENV.fetch('RECORD_NEW_VCR_CASSETTES', false)
  config.default_cassette_options = {
    record: record_cassettes ? :new_episodes : :none
  }
end
