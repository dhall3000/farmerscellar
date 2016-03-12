class BulkPurchasesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  
  def new
  	@bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	@bulk_purchase.load_unpurchased_receivables
  end

  def create
  	#filled_tote_items = ToteItem.find(params[:filled_tote_item_ids])
  	@purchase_receivables = PurchaseReceivable.find(params[:purchase_receivables])
  	if @purchase_receivables != nil && @purchase_receivables.count > 0
  	  @bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	  for pr in @purchase_receivables
  	    @bulk_purchase.purchase_receivables << pr
  	  end
      @bulk_purchase.go  	
      @num_payment_payables_created = @bulk_purchase.num_payment_payables_created
    end  	
  end
end
