class BulkPurchasesController < ApplicationController
  def new
  	@bulk_purchase = BulkPurchase.new
  	@bulk_purchase.load_unpaid_receivables
  end

  def create
  	#filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	@purchase_receivables = PurchaseReceivable.find(params[:purchase_receivables])
  	if @purchase_receivables != nil && @purchase_receivables.count > 0
  	  @bulk_purchase = BulkPurchase.new
  	  for pr in @purchase_receivables
  	    @bulk_purchase.purchase_receivables << pr
  	  end
      @bulk_purchase.go  	
    end  	
  end
end
