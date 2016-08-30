class PartnerUsersController < ApplicationController
  
  before_action :redirect_to_root_if_user_not_admin

  def index
    @partner_users = User.where(partner_user: true).order(:name)
    @dropsites = Dropsite.all
  end

  def create

    @user = User.find_by(email: params["email"])

    if @user
      #update the user
      @user.name = params["name"]
      @user.partner_user = true
    else
      #create the user
      @user = User.new(
        email: params["email"],
        password: "oxuntvZb{?c6193753cjapJ",
        name: params["name"],
        account_type: User.types[:CUSTOMER],
        activated: true,
        partner_user: true
        )

    end

    if @user.valid?
      if @user.save
        flash[:success] = "User saved"
      else
        flash[:danger] = "User not saved. Errors: #{@user.errors.messages}."          
      end
    else
      flash[:danger] = "User not saved. Errors: #{@user.errors.messages}."
    end

    if @user.dropsite.nil?
      dropsite = Dropsite.find(params["dropsite"])
      if dropsite
        @user.set_dropsite(dropsite)
      end      
    end

    if @user.pickup_code && @user.pickup_code.code
    else
      flash.clear
      flash[:danger] = "There is a problem with this user's pickup code. Investigate before sending delivery notification!"
    end

    redirect_to partner_users_index_path

  end

  def send_delivery_notification

    users = User.where(id: params["user_ids"])
    partner = params["partner_name"]

    users.each do |user|
      UserMailer.delivery_notification(user, user.dropsite, tote_items = nil, partner).deliver_now
      user.partner_deliveries.create(partner: partner)
    end

    flash[:success] = "Delivery notifications sent"
    redirect_to partner_users_index_path

  end

end