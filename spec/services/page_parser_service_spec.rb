# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageParserService do
  subject(:service) { described_class.new(body, headers) }

  let(:body) do
    html = '<html><head>'\
    '<title>title</title>'\
    '<meta name="description" content="desc"></meta>'\
    '<meta name="keywords" content="keywords"></meta>'\
    '<meta name="date" content="date"></meta>'\
    '</head></html>'

    Nokogiri::HTML(html)
  end

  let(:headers) { nil }

  describe '#initialize' do
    it { expect(service.body).to be_a Nokogiri::HTML::Document }
  end

  describe '#parse' do
    let(:expected_object) do
      {
        page_title: 'title',
        page_desc: 'desc',
        page_keywords: 'keywords',
        page_date: 'date'
      }
    end

    it { expect(service).to respond_to(:parse) }

    it 'extracts the metadata' do
      expect(service.parse).to eq expected_object
    end
  end

  describe '#last_modified' do
    let(:headers) { { 'last-modified': '2019-01-01' }.with_indifferent_access }

    it { expect(service).to respond_to(:last_modified) }

    it 'extracts last modified' do
      expect(service.last_modified).to eq(last_modified: Date.parse('2019-01-01').to_time.to_i)
    end

    context 'when headers are nil' do
      let(:headers) { nil }

      it { expect(service.last_modified).to eq(last_modified: '') }
    end
  end
end
