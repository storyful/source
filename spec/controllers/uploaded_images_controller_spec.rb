# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadedImagesController, type: :controller do
  let(:image) { create(:uploaded_image) }

  before do
    allow(UploadedImage).to receive(:new).and_return(image)
    allow(UploadedImage).to receive(:find)

    request.session[:logged_in] = 'true'
  end

  describe '#new' do
    it 'instantiate UploadedImage' do
      get :new

      expect(UploadedImage).to have_received(:new)
    end
  end

  describe '#edit' do
    it 'finds an uploaded image by id' do
      get :edit, params: { id: image.id }

      expect(UploadedImage).to have_received(:find).with(image.id.to_s)
    end
  end
end
