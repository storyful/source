# frozen_string_literal: true

class TranslateController < ApplicationController
  skip_before_action :verify_authenticity_token

  def translate
    if params[:translate_text].blank? || params[:translate_from].blank? || params[:translate_to].blank?
      render json: { error: 'Must include all parameters' } && return
    end

    render json: TextService.new.translate(
      params[:translate_text], params[:translate_from], params[:translate_to]
    ).as_json
  end
end
