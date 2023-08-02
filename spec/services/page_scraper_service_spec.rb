# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageScraperService do
  subject(:service) { described_class.new(pages) }

  MockTyphoeusRes = Struct.new(:body, :headers, :code)
  MockOpenUriRes = Struct.new(:meta)

  let(:pages) { [{ 'url' => 'https://example.com/' }] }
  let(:hydra) { instance_double(Typhoeus::Hydra) }
  let(:typhoeus_req) { instance_double(Typhoeus::Request) }
  let(:mock_typhoeus_response) { MockTyphoeusRes.new('test', {}) }
  let(:mock_openuri_response) { MockOpenUriRes.new('last-modified' => '2018-01-01') }

  it { expect(service.pages).to be_a Array }

  describe '#scrape' do
    before do
      allow(Nokogiri::HTML::Document).to receive(:parse).and_return('<html></html>')
      # allow(service).to receive(:open).and_return(mock_openuri_response)
      allow(Typhoeus::Hydra).to receive(:new).and_return(hydra)
      allow(Typhoeus::Request).to receive(:new).and_return(typhoeus_req)
      allow(hydra).to receive(:queue)
      allow(hydra).to receive(:run)
      allow(typhoeus_req).to receive(:response).and_return(MockTyphoeusRes.new('', {}, 200))
    end

    it { expect(service).to respond_to(:scrape) }

    it 'instantiate Typhoeus::Hydra' do
      service.scrape

      expect(Typhoeus::Hydra).to have_received(:new)
    end

    it 'creates a Typhoeus request' do
      service.scrape

      expect(Typhoeus::Request).to have_received(:new)
    end

    it 'adds a request to the queue' do
      service.scrape

      expect(hydra).to have_received(:queue)
    end

    it 'executes the requests' do
      service.scrape

      expect(hydra).to have_received(:run)
    end

    it 'returns responses' do
      expect(service.scrape).to eq('https://example.com/' => { page: pages[0], body: '<html></html>' })
    end
  end
end
