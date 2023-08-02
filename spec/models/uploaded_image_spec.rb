# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadedImage, type: :model do
  subject { described_class.new }

  context 'when mandatory field is nil' do
    subject { build(:uploaded_image) }

    it { is_expected.to validate_presence_of(:file) }
  end

  context 'when file is valid' do
    subject { build(:uploaded_image, :valid_image) }

    it { is_expected.to be_valid }
  end

  context 'when file is too large' do
    subject { build(:uploaded_image, :large_image) }

    it { is_expected.not_to be_valid }
  end

  context 'when file type is invalid' do
    subject { build(:uploaded_image, :invalid_type) }

    it { is_expected.not_to be_valid }
  end

  context 'when file type is invalid' do
    subject { build(:uploaded_image, :invalid_dimensions) }

    it { is_expected.not_to be_valid }
  end
end
