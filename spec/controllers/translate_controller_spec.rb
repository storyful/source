# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TranslateController, type: :controller do
  let(:text_service_double) { instance_double(TextService) }
  let(:translate_text) do
    "'മഞ്ജു വാര്യർ ഇനി മുതൽ \" മൈമൂന\"!!!\n' | പ്രശസ്ത മലയാള സിനിമാ
    താരം മഞ്ജു\n' വാര്യർ ഇസ്ലാം മതം സകരിച്ചു!!!\nഇന്നലെ വൈകിട്ട് വിനിമയിലെ\n
    സഹപ്രവർത്തകരുടെ സാന്നിദ്ധ്യത്തി\n- പൊന്നാനിയിൽ വെച്ചായിരുന്നു മതമാനം\n
    പ്രഖ്യാപിച്ചത\n"
  end
  let(:translate_from) { 'ml' }
  let(:translate_to) { 'en' }
  let(:translated_text) { 'this is the translated text' }

  before do
    allow(TextService).to receive(:new).and_return(text_service_double)
    allow(text_service_double).to receive(:translate).and_return(translated_text)
    session[:logged_in] = true
  end

  describe '#translate' do
    context 'when correct data is passed' do
      before do
        post :translate, params: {
          translate_text: translate_text, translate_from: translate_from, translate_to: translate_to
        }
      end
      it 'calls the translate service' do
        expect(TextService).to have_received(:new)
      end
      it 'calls the translate service with crrect params' do
        expect(text_service_double).to have_received(:translate).with(
          translate_text, translate_from, translate_to
        )
      end
    end
    context 'when parameters are missing' do
      it 'does not call the translate service' do
        post :translate, params: { translate_text: translate_text }

        expect(TextService).not_to have_received(:new)
      end
    end
  end
end
