# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user

  private

  def authenticate_user
    redirect_to auth_index_path if session[:logged_in].nil?
  end
end
