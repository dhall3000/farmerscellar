class BulkPurchase < ActiveRecord::Base
  has_many :bulk_purchase_receivables
  has_many :purchase_receivables, through: :bulk_purchase_receivables

  def load_unpaid_receivables
  	#TODO: this will probably be really inefficient as the db grows. maybe want a boolean for when each record is fully paid off
  	prs = PurchaseReceivable.where("amount_paid < amount")
  	if prs &&  prs.any?
  	  for pr in prs
  	  	purchase_receivables << pr
  	  end
  	end
  end

  def go
  	if purchase_receivables && purchase_receivables.any?
  	  for purchase_receivable in purchase_receivables
        purchase_receivable.purchase
  	  end
  	  save
  	end    
  end

end