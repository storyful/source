# frozen_string_literal: true

require 'rails_helper'

RSpec.describe URIParser, type: :service do
  describe '#self.parse_with_scheme' do
    context 'when url does not contain scheme' do
      let(:url) { 'google.com' }

      it 'returns uri with http scheme' do
        expect(URIParser.parse_with_scheme(url).scheme).to eq 'http'
      end
    end

    context 'when url contains http scheme' do
      let(:url) { 'http://google.com' }

      it 'returns uri with http scheme' do
        expect(URIParser.parse_with_scheme(url).scheme).to eq 'http'
      end
    end

    context 'when url contains https scheme' do
      let(:url) { 'https://google.com' }

      it 'returns uri with http scheme' do
        expect(URIParser.parse_with_scheme(url).scheme).to eq 'https'
      end
    end
  end
end
