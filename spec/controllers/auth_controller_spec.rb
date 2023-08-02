# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthController, type: :controller do
  describe 'create' do
    let(:passwords) { %w[example password] }
    let(:google_drive_double) { instance_double(GoogleDrive::Session) }
    let(:google_drive_reader_double) { instance_double(GoogleSheetReaderService) }
    let(:master_password) { '<%= ENV['MASTER_PASSWORD'] %>' }

    before do
      allow(GoogleDrive::Session).to receive(:from_service_account_key).and_return(google_drive_double)
      allow(GoogleSheetReaderService).to receive(:new).and_return(google_drive_reader_double)
      allow(google_drive_reader_double).to receive(:read).and_return(passwords)

      Settings[:master_password] = master_password
    end

    context 'when master password is not set in an env variable' do
      let(:master_password) { nil }

      before do
        post :create, params: { master_password: '<%= ENV['MASTER_PASSWORD'] %>' }
      end

      it 'creates a GoogleDrive Session' do
        expect(GoogleDrive::Session).to have_received(:from_service_account_key)
      end

      it 'creates a GoogleSheetReaderService instance' do
        expect(GoogleSheetReaderService).to have_received(:new)
      end

      context 'when password matches' do
        it { expect(response).to redirect_to root_path }
      end

      context 'when password does not match' do
        let(:passwords) { ['abc'] }

        it { expect(response).to redirect_to auth_index_path }
      end
    end

    context 'when master password is set in an env variable' do
      before do
        post :create, params: { master_password: '<%= ENV['MASTER_PASSWORD'] %>' }
      end

      it 'does not calls GoogleDrive APIs' do
        expect(GoogleDrive::Session).not_to have_received(:from_service_account_key)
        expect(GoogleSheetReaderService).not_to have_received(:new)
      end

      it 'redirects to the root' do
        expect(response).to redirect_to root_path
      end
    end
  end
end
