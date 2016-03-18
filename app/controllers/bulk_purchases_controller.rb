class BulkPurchasesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def new

    values = FundsProcessing.bulk_purchase_new
  	@bulk_purchase = values[:bulk_purchase]

  end

  def create

    values = FundsProcessing.bulk_purchase_create(params[:purchase_receivables])

    @bulk_purchase = values[:bulk_purchase]
    @purchase_receivables = @bulk_purchase.purchase_receivables
    @num_payment_payables_created = @bulk_purchase.num_payment_payables_created  	
  	
  end

end
