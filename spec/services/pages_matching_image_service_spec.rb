# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesMatchingImageService, vcr: true do
  subject(:service) { described_class.new(full, cache, whitelisted_urls, limit) }

  GoogleAnnotatorPage = Struct.new(:full_matching_images, :partial_matching_images, :page_title)

  let(:full) do
    [{ 'url' => 'https://example.com', 'page_title' => '' },
     { 'url' => 'http://test.com', 'page_title' => '' }]
  end

  let(:partial) do
    [{ 'url' => 'https://example.com', 'page_title' => '' }]
  end

  let(:scraped_pages) do
    { 'http://url1.com' => {
      page: GoogleAnnotatorPage.new(full, partial),
      body: 'test'
    } }
  end

  let(:whitelisted_urls) { [] }
  let(:limit) { nil }
  let(:cache) { {} }
  let(:hydra) { instance_double(Typhoeus::Hydra) }
  let(:page_parser_double) { instance_double(PageParserService) }
  let(:mock_parsed) { { page_desc: 'test desc', page_title: 'title', page_keywords: '', page_date: '' } }

  describe '#initialize' do
    it { expect(service.data).to be_a Array }

    context 'when data is invalid' do
      let(:cache) { [] }

      it { expect { service }.to raise_error ArgumentError }
    end
  end

  describe '#process' do
    let(:scraper_double) { instance_double(PageScraperService) }
    let(:image_scraper_double) { instance_double(ImageUrlScraperService) }

    before do
      allow(PageScraperService).to receive(:new).and_return(scraper_double)
      allow(scraper_double).to receive(:scrape).and_return(scraped_pages)

      allow(PageParserService).to receive(:new).and_return(page_parser_double)
      allow(page_parser_double).to receive(:parse).and_return(mock_parsed)

      allow(ImageUrlScraperService).to receive(:new).and_return(image_scraper_double)
      allow(image_scraper_double).to receive(:scrape)
    end

    it 'instantiate PageScraperService' do
      service.process

      expect(PageScraperService).to have_received(:new)
    end

    it 'instantiate PageParserService' do
      service.process
      expect(PageParserService).to have_received(:new).with('test', {})
      expect(page_parser_double).to have_received(:parse)
    end

    context 'when there is 1 full match and 0 partial' do
      let(:full) { [{ 'url' => 'http://example.com', 'page_title' => '' }] }
      let(:partial) { [] }

      it 'instantiate ImageScraperService' do
        service.process
        expect(ImageUrlScraperService).to have_received(:new)
      end
    end

    context 'when there is 1 full match and 1 partial' do
      let(:full) { [{ 'url' => 'http://example.com', 'page_title' => '' }] }
      let(:partial) { [{ 'url' => 'http://example2.com', 'page_title' => '' }] }

      it 'instantiate ImageScraperService' do
        service.process
        expect(ImageUrlScraperService).to have_received(:new).exactly(2).times
      end
    end

    context 'when whitelisted url does not include scheme' do
      let(:full) { [{ 'url' => 'organisation.com', 'page_title' => '' }] }
      let(:partial) { [] }
      let(:limit) { 2 }
      let(:whitelisted_urls) { ['organisation.com'] }

      it 'still passes it to PageScraperService' do
        service.process
        expect(PageScraperService).to have_received(:new).with(full)
      end
    end

    context 'when only one of two urls is whitelisted' do
      let(:partial) { [] }
      let(:limit) { 2 }
      let(:whitelisted_urls) { ['organisation.com'] }
      let(:full) do
        [{ 'url' => 'https://example.com', 'page_title' => '' },
         { 'url' => 'http://test.com', 'page_title' => '' },
         whitelisted_data]
      end
      let(:whitelisted_data) do
        { 'url' => 'http://organisation.com', 'page_title' => '' }
      end

      it 'calls PageScraperService only with whitelisted url' do
        service.process
        expect(PageScraperService).to have_received(:new)
          .once.with([whitelisted_data])
      end
    end

    context 'when number of whitelisted urls exceeds the limit' do
      let(:partial) { [] }
      let(:limit) { 2 }
      let(:whitelisted_urls) do
        ['organisation.com', 'google.com', 'thejournal.ie']
      end
      let(:full) do
        [{ 'url' => 'google.com', 'page_title' => '' },
         { 'url' => 'https://www.thejournal.ie/factcheck/news/', 'page_title' => '' },
         { 'url' => 'http://fakenews.com', 'page_title' => '' },
         { 'url' => 'http://organisation.com', 'page_title' => '' }]
      end

      let(:expected_data) do
        [{ 'url' => 'google.com', 'page_title' => '' },
         { 'url' => 'https://www.thejournal.ie/factcheck/news/',
           'page_title' => '' }]
      end

      it 'calls PageScraperService with only first two whitelisted urls' do
        service.process
        expect(PageScraperService).to have_received(:new)
          .once.with(expected_data)
      end
    end
  end
end
