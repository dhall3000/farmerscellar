class UploadsController < ApplicationController
  before_action :set_upload, only: [:show, :edit, :update, :destroy]
  before_action :redirect_to_root_if_user_not_admin
 
  def index
    @uploads = Upload.all
  end
 
  def show
  end
 
  def new
    @upload = Upload.new
  end
 
  def edit
  end
 
  def create
    @upload = Upload.new(post_upload_params)
 
    if @upload.save
      redirect_to @upload, notice: 'Upload was successfully created.'
    else
      render :new
    end
  end
 
  def update
    if @upload.update(post_upload_params)
      redirect_to @upload, notice: 'Upload attachment was successfully updated.'
    else
      render :edit
    end
  end
 
  def destroy
    @upload.destroy
    redirect_to uploads_url, notice: 'Upload was successfully destroyed.'
  end
 
  private

    def set_upload
      @upload = Upload.find(params[:id])
    end
 

    def post_upload_params
      params.require(:upload).permit(:name)
    end
end