# frozen_string_literal: true

class UploadedImagesController < ApplicationController
  def new
    @uploaded_image = UploadedImage.new
    @upload_error = upload_error
  end

  def create
    @uploaded_image = UploadedImage.create(uploaded_image_params)

    if @uploaded_image.valid?
      redirect_to edit_uploaded_image_path(id: @uploaded_image.uid)
    else
      flash[:image_error] = @uploaded_image.errors.messages
      redirect_to new_uploaded_image_path
    end
  end

  def edit
    @uploaded_image = UploadedImage.find(params[:id])
  end

  def update
    @uploaded_image = UploadedImage.update(params[:id], uploaded_image_params)

    new_search = Search.create(@uploaded_image, params[:id])
    redirect_to search_path(id: new_search.uid)
  end

  private

  def uploaded_image_params
    params.require(:uploaded_image).permit(:file, :uid, :original_filename, :crop_x, :crop_y, :crop_w, :crop_h, :scale_x, :scale_y, :rotate).to_h
  end

  def upload_error
    {
      file: ['Incorrect file type. <br>The allowed file types are .png, .jpg, .jpeg and .gif']
    }
  end
end
