class PaymentsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def index
    
  end

  def new
    @creditor_order = CreditorOrder.find_by(id: new_params[:creditor_order_id].to_i)
  end

  def create
  end

  private

    def new_params
      params.permit(:creditor_order_id)
    end

end
