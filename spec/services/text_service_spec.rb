# frozen_string_literal: true

require 'rails_helper'
require 'google/cloud/translate'

RSpec.describe TextService do
  subject(:service) { described_class.new }

  GoogleResponse = Struct.new(:web_detection) do
    def responses
      [
        web_detection
      ]
    end
  end

  MockTextAnnotations = Struct.new(:annotation) do
    def text_annotations
      [
        annotation
      ]
    end
  end

  MockExtractedText = Struct.new(:locale, :description)

  # rubocop: disable RSpec/VerifiedDoubles
  let(:translate_double) { double(Google::Cloud::Translate, translate: translate_response) }
  let(:translate_response) { double(Google::Cloud::Translate, text: true) }
  let(:annotators_double) { double(Google::Cloud::Vision::ImageAnnotator).as_null_object }
  # rubocop: enable RSpec/VerifiedDoubles
  let(:mock_response) { [{ code: 'en', name: 'english' }] }
  let(:search) { create(:search_with_uploaded_image) }

  let(:mock_annotation) { MockTextAnnotations.new(MockExtractedText.new('en', 'this is a test')) }
  let(:mock_extracted_text_response) { GoogleResponse.new(mock_annotation) }
  let(:translate_text) do
    "'മഞ്ജു വാര്യർ ഇനി മുതൽ \" മൈമൂന\"!!!\n' | പ്രശസ്ത മലയാള സിനിമാ
    താരം മഞ്ജു\n' വാര്യർ ഇസ്ലാം മതം സകരിച്ചു!!!\nഇന്നലെ വൈകിട്ട് വിനിമയിലെ\n
    സഹപ്രവർത്തകരുടെ സാന്നിദ്ധ്യത്തി\n- പൊന്നാനിയിൽ വെച്ചായിരുന്നു മതമാനം\n
    പ്രഖ്യാപിച്ചത\n"
  end
  let(:translate_from) { 'ml' }
  let(:translate_to) { 'en' }

  before do
    allow(Google::Cloud::Translate).to receive(:new).and_return(translate_double)
    allow(Google::Cloud::Vision::ImageAnnotator).to receive(:new).and_return(annotators_double)
    allow(translate_double).to receive(:languages).and_return(mock_response)
    allow(annotators_double).to receive(:document_text_detection).and_return(mock_extracted_text_response)

    service
  end

  describe '#initialize' do
    it { expect(Google::Cloud::Translate).to have_received(:new) }
    it { expect(Google::Cloud::Vision::ImageAnnotator).to have_received(:new) }
  end

  describe '#languages' do
    it 'returns supported languages' do
      expect(service.languages[0].keys).to eq %w[code name]
    end
  end

  describe '#extract_text' do
    it 'calls document_text_detection' do
      service.extract_text(search.uploaded_image)

      expect(annotators_double).to have_received(:document_text_detection)
    end

    it 'returns the extracted text' do
      expect(service.extract_text(search.uploaded_image)[:code]).to eq 'en'
      expect(service.extract_text(search.uploaded_image)[:text]).to eq 'this is a test'
    end
  end

  describe '#translate' do
    it 'calls google translate' do
      service.translate(translate_text, translate_from, translate_to)

      expect(translate_double).to have_received(:translate)
    end
  end
end
