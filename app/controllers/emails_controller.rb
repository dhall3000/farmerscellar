class EmailsController < ApplicationController
  #must be logged in: all
  before_action :logged_in_user
  #must be a producer or admin: all
  before_action :redirect_to_root_if_not_producer

  def index
  end

  def new

    @email = Email.new
    @open_postings = Posting.where(user: current_user, state: Posting.states[:OPEN])
    @committed_postings = Posting.where(user: current_user, state: Posting.states[:COMMITMENTZONE])

    if (@open_postings.nil? || !@open_postings.any?) && (@committed_postings.nil? || !@committed_postings.any?)
      flash[:danger] = "There are no postings to send a message to"
      redirect_to current_user
      return
    end

  end

  def create

    #verify existence of subject, body
    @email = Email.new(email_params)

    #verify correct_user
    postings = Posting.where(id: params[:posting_ids])
    postings.each do |posting|
      if posting.user.id != current_user.id
        flash[:danger] = "You can't send email to at least one of these postings"
        redirect_to current_user
        return
      end
    end

    if postings.nil? || !postings.any?
      flash[:danger] = "You must specify at least one posting to send email to"
      redirect_to current_user
      return
    end

    postings.each do |posting|
      @email.postings << posting
    end

    if @email.save
      #TODO: send the email
      flash[:success] = "Email successfully sent"
      redirect_to emails_path
      return
    else
      flash.now[:danger] = "Email failed to send"
      @open_postings = Posting.where(user: current_user, state: Posting.states[:OPEN])
      @committed_postings = Posting.where(user: current_user, state: Posting.states[:COMMITMENTZONE])
      render 'new'
      return
    end
    
  end

  def show
    email = Email.find_by(id: params[:id])

  end

  private

    def email_params
      return params.require(:email).permit(:subject, :body)
    end

end