require 'utility/funds_processing'

class BulkBuysController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new

    values = FundsProcessing.bulk_buy_new

  	@filled_tote_items = values[:filled_tote_items]    
    @user_infos = values[:user_infos]
    @total_bulk_buy_amount = values[:total_bulk_buy_amount]    

  end

  def create
    values = FundsProcessing.bulk_buy_create(params[:filled_tote_item_ids], current_user)
    @bulk_buy = values[:bulk_buy]    
  end
  
end
