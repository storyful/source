# frozen_string_literal: true

require 'rails_helper'
require 'google/cloud/storage'

RSpec.describe ImageProcessorService do
  subject(:service) { described_class.new(image) }

  # rubocop: disable RSpec/VerifiedDoubles
  let(:bucket_double) { double(Google::Cloud::Storage).as_null_object }
  # rubocop: enable RSpec/VerifiedDoubles
  let(:uploaded_image) { create(:uploaded_image) }
  let(:image) { Magick::Image.read(uploaded_image.file.path).first }

  before do
    allow(Google::Cloud::Storage).to receive(:new).and_return(bucket_double)
    allow(bucket_double).to receive(:bucket).and_return(bucket_double)
    allow(bucket_double).to receive(:file).and_return(File.open(Rails.root.join('spec', 'support', 'sample_100kb.jpg')))
  end

  describe '#initialize' do
    it { expect(service.image).to be_a Magick::Image }

    context 'when input is an instance of File' do
      let(:image) { File.open(Rails.root.join('spec', 'support', 'sample_100kb.jpg')) }

      it 'converts the file to MagickImage' do
        expect(service.image).to be_a Magick::Image
      end
    end

    context 'when input is invalid' do
      let(:image) { 'TEST' }

      it { expect { service }.to raise_error ArgumentError }
    end
  end

  describe '#crop' do
    let(:crop_params) do
      {
        crop_x: 0,
        crop_y: 10,
        crop_w: 0,
        crop_h: 50
      }
    end

    before do
      allow(service.image).to receive(:crop!)
    end

    it { expect(service).to respond_to(:crop) }

    it 'calls MagickImage crop' do
      service.crop(crop_params)

      expect(service.image).to have_received(:crop!).with(*crop_params.values)
    end

    context 'when params are nil' do
      let(:crop_params) { nil }

      it { expect { service.crop }.to raise_error ArgumentError }
    end

    context 'when params are invalid' do
      let(:crop_params) { { crop_h: 0 } }

      it { expect { service.crop(crop_params) }.to raise_error ArgumentError }
    end
  end

  describe '#flip_x' do
    before do
      allow(service.image).to receive(:flop!)
    end

    it { expect(service).to respond_to(:flip_x) }

    it 'calls MagickImage flop' do
      service.flip_x

      expect(service.image).to have_received(:flop!)
    end
  end

  describe '#flip_y' do
    before do
      allow(service.image).to receive(:flip!)
    end

    it { expect(service).to respond_to(:flip_y) }

    it 'calls MagickImage flip' do
      service.flip_y

      expect(service.image).to have_received(:flip!)
    end
  end

  describe '#flip_y' do
    before do
      allow(service.image).to receive(:rotate!)
    end

    it { expect(service).to respond_to(:rotate) }

    it 'calls MagickImage rotate' do
      service.rotate(90)

      expect(service.image).to have_received(:rotate!)
    end

    it 'sets a default value' do
      service.rotate

      expect(service.image).to have_received(:rotate!).with(0)
    end
  end
end
