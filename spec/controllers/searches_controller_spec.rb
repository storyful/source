# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

RSpec.describe SearchesController, type: :controller do
  let(:search) { instance_double(Search).as_null_object }

  describe '#show' do
    let(:search_service_double) { instance_double(SearchService) }
    let(:text_service_double) { instance_double(TextService) }

    let(:google_drive_double) { instance_double(GoogleDrive::Session) }
    let(:google_drive_reader_double) { instance_double(GoogleSheetReaderService) }
    let(:whitelisted_urls) { %w[http://www.20minutes.fr/societe/desintox/ https://www.altnews.in/] }
    let(:search_results) { { full_matches: [], partial_matches: [], verified: [] } }
    let(:extracted_text) { { text: 'test', code: 'en' } }

    before do
      allow(SearchService).to receive(:new).and_return(search_service_double)
      allow(search_service_double).to receive(:perform_search).and_return(search_results)
      allow(TextService).to receive(:new).and_return(text_service_double)
      allow(text_service_double).to receive(:extract_text).and_return(extracted_text)
      allow(text_service_double).to receive(:languages)

      allow(GoogleDrive::Session).to receive(:from_service_account_key).and_return(google_drive_double)
      allow(GoogleSheetReaderService).to receive(:new).and_return(google_drive_reader_double)
      allow(google_drive_reader_double).to receive(:read).and_return(whitelisted_urls)
      allow(Search).to receive(:find).and_return(search)
      allow(search).to receive(:store_results)

      session[:logged_in] = true
      get :show, params: { id: search.id }
    end

    it 'calls SearchService#perform_search' do
      expect(SearchService).to have_received(:new).with(search.uploaded_image, %w[20minutes.fr altnews.in], 10)
      expect(search_service_double).to have_received(:perform_search)
    end

    it 'calls TextService#extract_text' do
      expect(text_service_double).to have_received(:extract_text)
    end

    it 'creates a GoogleDrive Session' do
      expect(GoogleDrive::Session).to have_received(:from_service_account_key)
    end

    it 'creates a GoogleSheetReaderService instance' do
      expect(GoogleSheetReaderService).to have_received(:new)
    end

    it 'calls search method store_results' do
      expect(search).to have_received(:store_results).with(search_results, extracted_text)
    end
  end

  describe '#sort_and_filter_results' do
    let(:params) do
      { id: search.id, search: { 'results' => [{ last_modified: 'Wed, 16 Apr 2019 18:50:10 GMT' }, { last_modified: 'Tue, 15 Apr 2019 18:50:10 GMT' }], 'sort_order' => 'oldest', 'section' => 'full_matches' } }
    end

    let(:now) { '2019-04-25 09:00:00' }

    before do
      session[:logged_in] = true
      Timecop.freeze(now)
      post :sort_and_filter_results, params: params
    end

    it { expect(assigns(:full_matches)[0][:last_modified]).to eq 'Tue, 15 Apr 2019 18:50:10 GMT' }

    context 'when sort_order is newest' do
      let(:params) do
        { id: search.id, search: { 'results' => [{ last_modified: 'Tue, 10 Apr 2019 18:50:10 GMT' }, { last_modified: 'Tue, 22 Apr 2019 18:50:10 GMT'  }], 'sort_order' => 'newest', 'section' => 'full_matches' } }
      end

      it { expect(assigns(:full_matches)[0][:last_modified]).to eq 'Tue, 22 Apr 2019 18:50:10 GMT' }
    end

    context 'when filter by is last week' do
      let(:params) do
        { id: search.id, search: { 'results' => [{ last_modified: 'Wed, 24 Apr 2019 18:50:10 GMT' }, { last_modified: 'Fri, 05 Apr 2019 10:50:10 GMT'  }], 'sort_order' => 'oldest', 'filter_by' => '1 week', 'section' => 'full_matches' } }
      end

      it { expect(assigns(:full_matches).count).to eq 1 }
      it { expect(assigns(:full_matches)[0][:last_modified]).to eq 'Wed, 24 Apr 2019 18:50:10 GMT' }
    end

    context 'when filter by is 24 hours' do
      let(:params) do
        { id: search.id, search: { 'results' => [{ last_modified: 'Wed, 24 Apr 2019 18:50:10 GMT' }, { last_modified: 'Fri, 05 Apr 2019 10:50:10 GMT'  }], 'sort_order' => 'oldest', 'filter_by' => '24 hours', 'section' => 'full_matches' } }
      end

      let(:now) { '2019-04-26 09:00:00' }

      it { expect(assigns(:full_matches).count).to eq 0 }
    end

    context 'when filter by is all time' do
      let(:params) do
        { id: search.id, search: { 'results' => [{ last_modified: 'Wed, 24 Apr 2019 18:50:10 GMT' }, { last_modified: 'Fri, 05 Apr 2019 10:50:10 GMT'  }], 'sort_order' => 'oldest', 'filter_by' => 'all time', 'section' => 'full_matches' } }
      end

      let(:now) { '2019-04-26 09:00:00' }

      it { expect(assigns(:full_matches).count).to eq 2 }
    end
  end
end
