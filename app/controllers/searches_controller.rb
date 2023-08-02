# frozen_string_literal: true

class SearchesController < ApplicationController
  skip_before_action :verify_authenticity_token

  DATE_FORMAT = '%a, %d %b %Y %H:%M:%S'

  def show
    @search = Search.find(params[:id])

    fetch_languages
    fetch_filter_options

    @uploaded_image_new = UploadedImage.new

    @upload_errors = upload_error

    results = SearchService.new(@search.uploaded_image, whitelisted_urls, 10).perform_search

    slice_results(results)
    @extracted_text = TextService.new.extract_text(@search.uploaded_image, false)

    @search.store_results(results, @extracted_text)
  end

  def sort_and_filter_results
    subset = search_params[:results]
    subset = filter(subset, search_params[:filter_by]) if search_params[:filter_by].present?
    subset = sort(subset, search_params[:sort_order])
    instance_variable_set("@#{search_params[:section]}", subset)

    render partial: "searches/#{search_params[:section]}.html.erb", format: :html
  end

  def trigger_full_analysis
    SearchWorker.perform_async(params[:id], whitelisted_urls)

    render json: { started: true }
  end

  def full_results
    respond_to do |format|
      results = full_results_from_cache(params[:id])

      format.html do
        render plain: '' && return if results.nil?
        refresh_instance_variables(results)

        render partial: "searches/#{search_params[:section]}.html.erb", format: :html
      end

      format.json { render json: { results: JSON.parse(results) } }
    end
  end

  private

  def refresh_instance_variables(results)
    section = search_params[:section]
    subset = JSON.parse(results)[section].map(&:with_indifferent_access)

    subset = sort(subset, 'newest')
    instance_variable_set("@#{section}", subset)
  end

  def full_results_from_cache(id)
    Redis.current.get("search:#{id}:full_results")
  end

  def upload_error
    { file: ['Incorrect file type. The allowed file types are'\
             ' .png, .jpg, .jpeg and .gif'] }
  end

  def slice_results(results)
    @full_matches = sort(results[:full_matches], 'newest')
    @partial_matches = sort(results[:partial_matches], 'newest')
    @verified = sort(results[:verified], 'newest')
    total = @full_matches.length + @partial_matches.length + @verified.length
    @total_results = total >= 500 ? '500+' : total
  end

  def whitelisted_urls
    key = 'whitelisted_urls'
    in_cache = Rails.cache.fetch(key)
    return in_cache if in_cache.present? && in_cache.count > 5

    session = GoogleDrive::Session.from_service_account_key(Settings.google.credentials)
    urls = GoogleSheetReaderService.new(session, Settings.google.sheet_whitelist_urls_id, 4).read
    whitelisted = urls.map { |url| URIParser.parse_with_scheme(url).host&.gsub(/www\./, '') }
    Rails.cache.write(key, whitelisted)
    whitelisted
  rescue StandardError
    []
  end

  def fetch_filter_options
    @filter_options = Rails.cache.fetch('filter_options') do
      { 'past day' => '24 hours',
        'past week' => '1 week',
        'past month' => '1 month',
        'past year' => '1 year',
        'all time' => 'all time' }
    end
  end

  def fetch_languages
    @languages = Rails.cache.fetch('languages_list') do
      TextService.new.languages(true)
    end
  end

  def sort(data, order)
    data = data.sort { |a, b| Time.strptime(a[:last_modified], DATE_FORMAT) <=> Time.strptime(b[:last_modified], DATE_FORMAT) }
    order == 'newest' ? data.reverse : data
  end

  def filter(data, period)
    return data if period == 'all time'
    time = period.split(' ')
    start_time = time[0].to_i.send(time[1]).ago
    data.select { |result| Time.strptime(result[:last_modified], DATE_FORMAT) >= start_time }
  rescue StandardError
    data
  end

  def search_params
    results_keys = %i[page_desc page_title page_keywords page_date page_url
                      image_url last_modified]
    params.require(:search).permit(:section, :sort_order, :filter_by,
                                   results: results_keys)
  end
end
