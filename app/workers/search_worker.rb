# frozen_string_literal: true

class SearchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(search_id, whitelisted_urls)
    search = Search.find(search_id)
    results = SearchService.new(search.uploaded_image, whitelisted_urls).perform_search

    full_results = Redis::Value.new("search:#{search_id}:full_results")
    full_results.value = results.to_json

    full_results
  end
end
