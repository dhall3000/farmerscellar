class BulkPurchasesController < ApplicationController
  def new
  	@bulk_purchase = BulkPurchase.new
  	@bulk_purchase.load_unpaid_receivables
  end

  def create
  end
end
