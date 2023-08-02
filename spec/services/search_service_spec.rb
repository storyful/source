# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchService do
  subject(:service) { described_class.new(image_path, whitelisted_urls, limit) }

  GoogleResponse = Struct.new(:web_detection) do
    def responses
      [
        web_detection
      ]
    end
  end

  GoogleWebDetection = Struct.new(:web_detection)
  GoogleWebDetectionPages = Struct.new(:pages_with_matching_images, :visually_similar_images, :best_guess_labels, :web_entities)

  let(:limit) { nil }
  let(:whitelisted_urls) { %w[verified.com] }
  let(:image_path) { 'tmp/example.jpg' }
  let(:json) { JSON.parse File.read(Rails.root.join('spec', 'fixtures', 'sample.json')) }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:annotator_double) { double(Google::Cloud::Vision::ImageAnnotator).as_null_object }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:pages_matching_image_double) { instance_double(PagesMatchingImageService) }
  let(:similar_images_double) { instance_double(SimilarImagesService) }
  let(:guess_labels) { [{ 'label' => 'test' }] }
  let(:web_entities) do
    [{
      'entityId' => '/m/08pcth',
      'score' => 5.7674999,
      'description' => 'test'
    }]
  end
  let(:web_detection_pages) { GoogleWebDetectionPages.new([], [], guess_labels, web_entities) }
  let(:web_detection) { GoogleWebDetection.new(web_detection_pages) }
  let(:mock_response) { GoogleResponse.new(web_detection) }

  before do
    allow(Google::Cloud::Vision::ImageAnnotator).to receive(:new).and_return(annotator_double)
    allow(annotator_double).to receive(:web_detection).and_return(mock_response)
    allow(PagesMatchingImageService).to receive(:new).and_return(pages_matching_image_double)
    allow(pages_matching_image_double).to receive(:process)

    allow(SimilarImagesService).to receive(:new).and_return(similar_images_double)
    allow(similar_images_double).to receive(:process)
  end

  describe '#initialize' do
    it { expect(service.results.keys).to match_array %i[verified full_matches partial_matches similar_images] }
  end

  describe '#perform_search' do
    let(:sample_response) do
      {
        verified: [],
        full_matches: [
          {
            page_desc: 'Test desc',
            page_title: 'Test title',
            page_keywords: 'Security, Security, Middle East, Syria Civil War, Assad',
            page_date: '',
            page_url: 'https://nationalinterest.org/blog/skeptics/assads-suffering-syria-seeks-reconciliation-arab-world-34592',
            image_url: 'https://nationalinterest.org/sites/default/files/styles/desktop__1486_x_614/public/main_images/RTX6FZ2R.jpg',
            last_modified: 'Mon, 29 Oct 2018 14:15:16 GMT'
          },
          {
            page_desc: 'Test desc2',
            page_title: 'Test title2',
            page_keywords: 'Keyword',
            page_date: '',
            page_url: 'https://verified.com/blog/skeptics/assads-suffering-syria-seeks-reconciliation-arab-world-34592',
            image_url: 'https://test.com/sites/default/files/styles/desktop__1486_x_614/public/main_images/RTX6FZ2R.jpg',
            last_modified: 'Mon, 29 Oct 2018 14:15:16 GMT'
          }
        ],
        partial_matches: []
      }
    end

    it 'returns an aray' do
      service.perform_search
      expect(service.response.responses).to be_a Array
    end

    it 'extract verified urls' do
      service.results = sample_response
      service.perform_search
      expect(service.results[:full_matches].count).to eq 1
      expect(service.results[:verified].count).to eq 1
    end

    it 'calls PagesMatchingImagesService#process' do
      service.perform_search
      count = service.response.responses.count
      expect(pages_matching_image_double).to have_received(:process).exactly(count).times
    end
  end

  describe '#verified?' do
    let(:whitelisted_urls) { %w[aap.com.au dubawa.org] }
    let(:url) { 'https://check4spam.com/manju-warrier-converts-islam-name-maimuuna-hoax/' }

    it { expect(service.verified?(url)).to eq false }

    context 'when domain is verified' do
      let(:url) { 'https://dubawa.org/manju-warrier-converts-islam-name-maimuuna-hoax/' }

      it { expect(service.verified?(url)).to eq true }
    end
  end
end
