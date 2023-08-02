# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search, type: :model do
  subject { described_class.new }

  let(:redis_value) { instance_double(Redis::Value).as_null_object }

  before do
    allow(Redis::Value).to receive(:new).and_return(redis_value)
    allow(redis_value).to receive(:value)
  end

  context 'when uploaded image is valid' do
    subject { build(:search_with_uploaded_image) }

    it { is_expected.to be_valid }
  end

  context 'when uploaded image is nil' do
    subject { build(:search) }

    it { is_expected.not_to be_valid }
  end

  describe '#store_results' do
    let(:search) { create(:search_with_uploaded_image) }

    let(:search_results) { { full_matches: [] } }
    let(:extracted_text) { { text: 'test', code: 'en' } }

    before do
      search.store_results(search_results, extracted_text)
    end

    it { expect(Redis::Value).to have_received(:new).exactly(3).times }
  end
end
