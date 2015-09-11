class BulkPurchasesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def new
  	@bulk_purchase = BulkPurchase.new(total_gross: 0, total_fee: 0, total_commission: 0, total_net: 0)
  	@bulk_purchase.load_unpaid_receivables
  end

  def create
  	#filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	@purchase_receivables = PurchaseReceivable.find(params[:purchase_receivables])
  	if @purchase_receivables != nil && @purchase_receivables.count > 0
  	  @bulk_purchase = BulkPurchase.new(total_gross: 0, total_fee: 0, total_commission: 0, total_net: 0)
  	  for pr in @purchase_receivables
  	    @bulk_purchase.purchase_receivables << pr
  	  end
      @bulk_purchase.go  	
    end  	
  end
end
