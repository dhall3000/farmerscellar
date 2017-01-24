class UploadsController < ApplicationController
  before_action :set_upload, only: [:show, :edit, :update, :destroy]
  before_action :redirect_to_root_if_user_not_admin, only: [:index, :edit, :update]
  before_action :redirect_to_root_if_not_producer, only: [:show, :new, :create, :destroy]
 
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

    if params[:upload].nil?
      flash[:danger] = "Incorrect upload parameters"
      redirect_to user_path(current_user)
      return
    end

    @upload = Upload.new(post_upload_params)
    
    if @upload.save

      flash[:success] = "Uploaded successfully"

      if params[:posting_id]
        posting = Posting.find(params[:posting_id])
        posting.uploads << @upload
        posting.save
        redirect_to edit_posting_path(posting)
        return
      else
        redirect_to user_path(current_user)
        return
      end

    else

      flash[:danger] = "Upload failed"
      redirect_to user_path(current_user)
      return

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

    #make sure no postings are pointing at this upload
    @upload.postings.each do |posting|
      @upload.postings.delete(posting)
    end

    posting = nil

    #if we've gotten here with an associated posting, nuke the association
    if params[:posting_id]
      #make sure this posting is not pointing at this upload
      posting = Posting.find(params[:posting_id])
      posting.uploads.delete(@upload)
    end

    if @upload.destroy
      flash[:success] = "Upload deleted"
    else
      flash[:danger] = "Upload not deleted"
    end

    if posting
      redirect_to edit_posting_path(posting)
    else
      redirect_to uploads_path
    end

  end
 
  private

    def set_upload
      @upload = Upload.find(params[:id])
    end
 

    def post_upload_params      
      params.require(:upload).permit(:file_name, :title)
    end
end