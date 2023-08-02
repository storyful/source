# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user, only: %i[index create]

  def index; end

  def create
    unless valid_password?
      redirect_to auth_index_path, flash: { error: 'Invalid password' }
      return
    end

    session[:logged_in] = Time.zone.now.to_i
    redirect_to root_path
  end

  private

  def valid_password?
    return true if params[:master_password] == Settings.master_password

    remote_passcodes.include?(params[:master_password])
  end

  def remote_passcodes
    session = GoogleDrive::Session.from_service_account_key(Settings.google.credentials)
    GoogleSheetReaderService.new(session, Settings.google.sheet_passcodes_id).read
  end
end
