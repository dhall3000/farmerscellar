class UploadsController < ApplicationController
  before_action :set_upload, only: [:show, :edit, :update, :destroy]
  before_action :redirect_to_root_if_user_not_admin, only: [:index, :edit, :update]
  before_action :redirect_to_root_if_not_producer, only: [:show, :new, :create, :destroy]
 
  def index
    @uploads = Upload.where.not(title: nil)
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

    if !@upload.valid?
      flash.now[:danger] = "Invalid upload"
      render 'uploads/new'
      return
    end
    
    if @upload.save

      flash[:success] = "Uploaded successfully"

      if params[:posting_id]
        posting = Posting.find(params[:posting_id])
        posting.uploads << @upload
        posting.save
        redirect_to edit_posting_path(posting)
        return
      elsif params[:food_category_id]
        food_category = FoodCategory.find(params[:food_category_id])
        food_category.uploads << @upload
        food_category.save
        redirect_to edit_food_category_path(food_category)
        return
      else
        redirect_to @upload
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

    @upload.food_categories.each do |food_category|
      @upload.food_categories.delete(food_category)
    end

    posting = nil

    #if we've gotten here with an associated posting, nuke the association
    if params[:posting_id]
      #make sure this posting is not pointing at this upload
      posting = Posting.find(params[:posting_id])
      posting.uploads.delete(@upload)
    end

    #if we've gotten here with an associated food_category, nuke the association
    if params[:food_category_id]
      #make sure this food_category is not pointing at this upload
      food_category = FoodCategory.find(params[:food_category_id])
      food_category.uploads.delete(@upload)
    end

    if @upload.destroy
      flash[:success] = "Upload deleted"
    else
      flash[:danger] = "Upload not deleted"
    end

    if posting
      redirect_to edit_posting_path(posting)
    elsif food_category
      redirect_to edit_food_category_path(food_category)        
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