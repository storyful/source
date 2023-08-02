# frozen_string_literal: true

require 'rails_helper'
require 'google/cloud/storage'

RSpec.describe FileUploader do
  let(:uploaded_image) { create(:uploaded_image) }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:bucket_double) { double(Google::Cloud::Storage).as_null_object }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:image_processor) { instance_double(ImageProcessorService) }
  let(:image) { File.open(Rails.root.join('spec', 'support', 'sample_100kb.jpg')) }

  before do
    stub_const('ImageUploader::TEMP_FOLDER', 'spec/fixtures/uploaded')
    allow(Google::Cloud::Storage).to receive(:new).and_return(bucket_double)
    allow(bucket_double).to receive(:bucket).and_return(bucket_double)
    allow(bucket_double).to receive(:file).and_return(bucket_double)
    allow(bucket_double).to receive(:name).and_return('image.jpeg')
    allow(bucket_double).to receive(:download)
  end

  describe '#apply_filters' do
    before do
      allow(ImageProcessorService).to receive(:new).and_return(image_processor)
      allow(image_processor).to receive(:crop)
      allow(image_processor).to receive(:flip_x)
      allow(image_processor).to receive(:flip_y)
      allow(image_processor).to receive(:rotate)
      allow(image_processor).to receive(:image)

      uploaded_image.file.apply_filters(image)
    end

    it { expect(uploaded_image.file).to respond_to(:apply_filters) }
    it { expect(ImageProcessorService).to have_received(:new) }

    context 'when crop params are not nil' do
      let(:uploaded_image) { create(:uploaded_image, crop_x: 0) }

      it { expect(image_processor).to have_received(:crop) }
    end

    context 'when crop params are nil' do
      let(:uploaded_image) { create(:uploaded_image) }

      it { expect(image_processor).not_to have_received(:crop) }
    end

    context 'when scale_x is -1' do
      let(:uploaded_image) { create(:uploaded_image, scale_x: -1) }

      it { expect(image_processor).to have_received(:flip_x) }
    end

    context 'when scale_x is not -1' do
      let(:uploaded_image) { create(:uploaded_image) }

      it { expect(image_processor).not_to have_received(:flip_x) }
    end

    context 'when scale_y is -1' do
      let(:uploaded_image) { create(:uploaded_image, scale_y: -1) }

      it { expect(image_processor).to have_received(:flip_y) }
    end

    context 'when scale_y is not -1' do
      let(:uploaded_image) { create(:uploaded_image) }

      it { expect(image_processor).not_to have_received(:flip_y) }
    end

    context 'when rotate is > 0' do
      let(:uploaded_image) { create(:uploaded_image, rotate: 90) }

      it { expect(image_processor).to have_received(:rotate) }
    end

    context 'when rotate is not > 0' do
      let(:uploaded_image) { create(:uploaded_image) }

      it { expect(image_processor).not_to have_received(:rotate) }
    end
  end
end
