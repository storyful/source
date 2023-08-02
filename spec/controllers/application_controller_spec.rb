# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render json: {}
    end
  end

  describe '#index' do
    it 'returns 302' do
      get :index

      expect(response).to have_http_status(:redirect)
    end

    it 'returns 200' do
      request.session[:logged_in] = 'true'
      get :index

      expect(response).to have_http_status(:ok)
    end
  end
end
