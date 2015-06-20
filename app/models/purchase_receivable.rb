class PurchaseReceivable < ActiveRecord::Base
  has_many :bulk_buy_purchase_receivables
  has_many :bulk_buys, through: :bulk_buy_purchase_receivables

  has_many :user_purchase_receivables
  has_many :users, through: :user_purchase_receivables

  has_many :purchase_receivable_tote_items
  has_many :tote_items, through: :purchase_receivable_tote_items

  has_many :bulk_purchase_receivables
  has_many :bulk_purchases, through: :bulk_purchase_receivables

  has_many :purchase_purchase_receivables
  has_many :purchases, through: :purchase_purchase_receivables

  def purchase    
    
    authorization = nil

    if tote_items && tote_items.any?
      authorization = tote_items.last.authorization
    end

    if authorization == nil
      #TODO: we should probably raise this for the admin to manually process
      #this block happens if we somehow didn't find an authorization to use
      #debugger
      return nil
    end

    #we don't want to capture more than the purchase_receivable outstanding amount is
    #likewise, we don't want to attempt to capture more than is available on this authorization
    #so, select the lesser of the two    
    purchase_receivable_amount_outstanding = amount - amount_paid
    authorization_amount_outstanding = authorization.amount - authorization.amount_purchased
    amount_to_capture = [purchase_receivable_amount_outstanding, authorization_amount_outstanding].min    

    purchase = Purchase.new    
    purchase.go(amount_to_capture * 100, authorization.payer_id, authorization.transaction_id)
        
    if purchase == nil
      #TODO: hmm, error. not sure what we should do here. we tried to create a purchase but it just totally failed. this should be impossible
    else        	
      purchases << purchase      
      self.amount_paid += purchase.gross_amount      
      authorization.amount_purchased += purchase.gross_amount
      authorization.save
    end

    return purchase
  end
end