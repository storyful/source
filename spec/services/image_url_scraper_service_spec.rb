# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageUrlScraperService do
  subject(:service) { described_class.new(url, page, cache, hydra) }

  MockResponse = Struct.new(:headers)

  let(:url) { 'http://example.com?test=true' }
  let(:cache) { [] }
  let(:hydra) { instance_double(Typhoeus::Hydra) }
  let(:request_double) { instance_double(Typhoeus::Request) }
  let(:page) do
    {
      page_title: 'title',
      page_desc: 'desc',
      page_keywords: 'keywords',
      page_date: 'date'
    }
  end

  describe '#initialize' do
    it { expect(service.url).to eq 'http://example.com' }
    it { expect(service.cache).to be_a Array }
    it { expect(service.page).to be_a Hash }
  end

  describe '#scrape' do
    before do
      allow(Typhoeus::Hydra).to receive(:new).and_return(hydra)
      allow(Typhoeus::Request).to receive(:new).and_return(request_double)
      allow(request_double).to receive(:on_complete).and_yield(MockResponse.new('last-modified' => 'Sat, 24 Nov 2018 02:20:27 GMT'))
      allow(hydra).to receive(:queue)
      service.scrape
    end

    it { expect(Typhoeus::Request).to have_received(:new) }

    it { expect(service.cache[0]).to have_key(:last_modified) }
    it { expect(service.cache[0]).to have_key(:image_url) }
  end
end
