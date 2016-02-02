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

  def self.kind
    {NORMAL: 0, PURCHASEFAILED: 1}
  end

  def self.load_unpaid_purchase_receivables
    #TODO(Future): this will probably be really inefficient as the db grows. maybe want a boolean for when each record is fully paid off
    prs = where("amount_paid < amount and (kind is null or kind = ?)", PurchaseReceivable.kind[:NORMAL])

    #TODO (future): this method gets called because we're in process of charging customer accounts. with the code as is, each
    #object returned in 'prs' will get charged. but by doing so the door is a tiny bit open to double charging customers.
    #it works like this: below (in method 'purchase') we call the following line:
    #purchase.go(amount_to_capture * 100, authorization.payer_id, authorization.transaction_id)
    #this is the line of code that does the actual money moving. but what if, after the transaction goes through, things get interrupted
    #before we call the following two lines of code:
    #self.amount_paid += purchase.gross_amount      
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

  #return a hash where the keys are producer ids and the values are arrays of tote_items from that producer
  def get_sub_totes_by_producer_id

  	sub_totes_by_producer_id = {}
  	producer_ids = get_producer_ids    

  	for producer_id in producer_ids
  	  sub_tote = get_sub_tote(producer_id)      
  	  sub_totes_by_producer_id[producer_id] = sub_tote
  	end

  	return sub_totes_by_producer_id

  end

  #returns an array of all tote_items for the given producer id
  def get_sub_tote(producer_id)

  	sub_tote = []
    tote_items.each do |tote_item|
      if tote_item.posting.user.id == producer_id
      	sub_tote << tote_item
      end
    end  

    return sub_tote

  end

  #returns an array of the producer ids in this purchase receivable
  def get_producer_ids

  	producer_ids = []
    tote_items.each do |tote_item|
      producer_ids << tote_item.posting.user.id
    end

    return producer_ids.uniq

  end

  def purchase    
    
    authorization = nil

    if tote_items && tote_items.any?
      authorization = tote_items.last.authorization
    else
      puts "returning nil because there were no ToteItem objects when trying to do PurchaseReceivable.purchase()."
      return nil      
    end

    if authorization == nil
      puts "returning nil because there was no authorization object when trying to do PurchaseReceivable.purchase()."
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
      puts "Purchase object is nil. this should be impossible. we are in PurchaseReceivable.purchase() method."
    else
      purchases << purchase
      if purchase.response.success?
        self.amount_paid = (self.amount_paid + purchase.gross_amount).round(2)
        #the following 'save' is important to do because it 'closes the door' on the liklihood that we'll double charge the customer.
        #this is so because we know to charge by comparing the .amount_paid attribute so we want to save to db asap after collecting funds
        save
        authorization.amount_purchased = (authorization.amount_purchased + purchase.gross_amount).round(2)
        authorization.save            
        tote_items.where(status: ToteItem.states[:PURCHASEPENDING]).update_all(status: ToteItem.states[:PURCHASED])
      else        
        tote_items.where(status: ToteItem.states[:PURCHASEPENDING]).update_all(status: ToteItem.states[:PURCHASEFAILED])
        self.kind = PurchaseReceivable.kind[:PURCHASEFAILED]

        #we want to prevent work from beginning on any tote_items in this customer's pipeline for which work hasn't yet begun
        #in other words, empty out their tote. however, if something is already committed then the customer is on the hook for
        #that if it gets filled.
        #TODO: make a test to verify that when a purchase fails the shopping tote gets emptied
        current_tote_items = ToteItemsController.helpers.current_tote_items_for_user(users.last)
        if current_tote_items != nil && current_tote_items.any?
          current_tote_items.where("status = ? or status = ?", ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED]).update_all(status: ToteItem.states[:REMOVED])
        end

        #put this user's account on hold so they can't order again until they clear up this failed purchase        
        UserAccountState.add_new_state(users.last, :HOLD, "purchase failed")

        save
      end

    end

    return purchase
  end
end