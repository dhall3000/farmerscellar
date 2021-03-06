class PurchaseReceivable < ApplicationRecord
  attr_accessor :amount_to_capture

  has_many :rtpurchase_prs
  has_many :rtpurchases, through: :rtpurchase_prs

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

  def self.kind
    {NORMAL: 0, PURCHASEFAILED: 1}
  end

  def self.states
    {READY: 0, COMPLETE: 1}
  end

  def self.transition(input, params = {})    
    transition_normal(input, params)
    transition_purchase_failed(input, params)
  end

  def self.transition_normal(input, params = {})    
    case input
    when :do_purchase
      #get all prs that are in state READY
    when :completed
      if params != nil && params[:purchase_receivables] != nil
        params[:purchase_receivables].each do |pr|
          pr.update(state: PurchaseReceivable.states[:COMPLETE])
        end
      end
    when :purchase_failed
      if params != nil && params[:purchase_receivables] != nil
        params[:purchase_receivables].each do |pr|

          pr.update(kind: PurchaseReceivable.kind[:PURCHASEFAILED], state: PurchaseReceivable.states[:READY])

          #we want to prevent work from beginning on any tote_items in this customer's pipeline for which work hasn't yet begun
          #in other words, empty out their tote. however, if something is already committed then the customer is on the hook for
          #that if it gets filled.
          #TODO: make a test to verify that when a purchase fails the shopping tote gets emptied
          current_tote_items = ToteItemsController.helpers.all_items_for(pr.users.order("users.id").last)
          if current_tote_items != nil && current_tote_items.any?
            current_tote_items.where("tote_items.state = ? or tote_items.state = ?", ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED]).each do |tote_item|
              tote_item.transition(:system_removed)
            end
          end          

        end
      end
    end
  end

  def self.transition_purchase_failed(input, params = {})
    #TODO: implement this some day?
  end

  def self.load_unpurchased_purchase_receivables_for_users(users)    
    all_prs = where(state: states[:READY], kind: kind[:NORMAL])
    uprs = UserPurchaseReceivable.select(:purchase_receivable_id).where(user_id: users, purchase_receivable_id: all_prs)
    prs = PurchaseReceivable.where(id: uprs)

    #TODO (future): this method gets called because we're in process of charging customer accounts. with the code as is, each
    #object returned in 'prs' will get charged. but by doing so the door is a tiny bit open to double charging customers.
    #it works like this: below (in method 'purchase') we call the following line:
    #purchase.go(amount_to_capture * 100, authorization.payer_id, authorization.transaction_id)
    #this is the line of code that does the actual money moving. but what if, after the transaction goes through, things get interrupted
    #before we call the following two lines of code:
    #self.amount_purchased += purchase.gross_amount      
    #save
    #what happens is the next time this method gets called we would return a purchasereceivable object to get charged that shouldn't
    #get charged. to fix this, what we need to do right here is:
    #for each pr in prs
    # ask paypal if any funds have been moved against the authorization associated with this pr
    #end
    #only if paypal responds saying no funds have been moved should we include this pr in the prs return set.
    #question: how do we get the authorization associated with this pr? although there is no direct db association, there is a
    #one-to-one correspondance between authorization and purchase_receivable and these are made by the toteitems, wich have a many-to-one
    #relationship with an authorization. so, from the pr, to get your auth, select any one tote_item in your tote_items array and then go
    #tote_item.checkouts.last.authorizations.last to query paypal if any funds have been drawn. once you do this you'll have a bullet
    #proof, idempotent payment execution flow.

    return prs
  end

  def amount_outstanding
    self.amount - self.amount_purchased
  end

  def apply(amount)

    self.amount_purchased = (self.amount_purchased + amount).round(2)

    if amount_outstanding == 0
      PurchaseReceivable.transition(:completed, {purchase_receivables: [self]})
    end

    save

  end

  def tote_item

    #we've gone to a model where each pr only has a single tote item so let's make it easier to access this tote item

    if tote_items.any?
      return tote_items.first
    else
      return nil
    end

  end

  def creditor

    if tote_item.nil? || tote_item.posting.nil?
      return nil
    end

    return tote_item.posting.get_creditor

  end

end