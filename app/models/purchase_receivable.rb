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

  def create_payment_payable(purchase = nil)

    if purchase.nil?

      #this is the "new" path. what i mean is when we started FC we had one model in mind (producers get paid
      #if and only if FC collects from customers). we also used to have multiple tote items per pr and multiple
      #purchases per pr. or something like that. well actually i think we still do have multiple purchases per
      #pr, if need be. anyway, we're simplifying. one tote item triggers generation of one purchase receivable
      #triggers generation of one payment payable
      #but more to the point here, we're now makign two code paths. one that generates payment payable after
      #a purchase has been amde and another that generates the payment payable right when the tote item is filled.
      #this latter case is way simpler so we're going to make two methods in one. ugly. get 'er done.

      #NOTE: this is dangerous. it's being written after we switched to having a single ti per pr. it could still
      #work if you had multiple tis per pr but ONLY if all the prs were from the same producer
      
      if !creditor
        return
      end

      net = get_producer_net_tote(tote_items, filled = true)      
      payment_payable = PaymentPayable.new(amount: net.round(2), amount_paid: 0)        

      payment_payable.users << creditor
      payment_payable.tote_items << tote_item

      payment_payable.save

      return

    end

    num_payment_payables_created = 0
    net_total = 0
    commission_total = 0
    
    amount_previously_purchased = amount_purchased - purchase.gross_amount
    gross_amount_payable = purchase.gross_amount

    #this cutoff amount var is an odd, but necessary duck. say you have a pr that collects funds to pay
    #to 4 different producers, each $20. but say the customer only pays 35 on the first purchase (for whatever
    #reason). this customer is going to have to make another future purchase to bring their account to zero.
    #when they make this second purchase we want to direct funds to the producers properly. in this example,
    #the first producer got maid whole, the second was partially paid and the last 2 weren't paid at all. so for
    #the second purchase we'd need to pay down the #2 producer and then pay off the last 2. the cutoff_amount
    #var tracks where the final amount to pay to farmer #2 is before switching to pay off #3 & #4.
    cutoff_amount = 0

    sub_tote_value_by_payment_sequenced_producer_id = get_sub_tote_value_by_payment_sequenced_producer_id
    sub_tote_value_by_payment_sequenced_producer_id.each do |producer_id, value|

      if gross_amount_payable <= 0
        next
      end

      cutoff_amount = (cutoff_amount + value[:sub_tote_value]).round(2)
      if amount_previously_purchased > cutoff_amount
        next
      end

      amount_remaining_to_pay_to_this_producer = cutoff_amount - amount_previously_purchased
      gross_amount_payable_to_this_producer = [gross_amount_payable, amount_remaining_to_pay_to_this_producer].min
      amount_previously_purchased = (amount_previously_purchased + gross_amount_payable_to_this_producer).round(2)
      gross_amount_payable = (gross_amount_payable - gross_amount_payable_to_this_producer).round(2)

      if purchase
        purchase.payment_processor_fee_withheld_from_producer = (purchase.payment_processor_fee_withheld_from_producer + get_payment_processor_fee_tote(value[:sub_tote], filled = true)).round(2)
      end
      
      commission = get_commission_tote(value[:sub_tote], filled = true)
      net = get_producer_net_tote(value[:sub_tote], filled = true)
      
      commission_total = (commission_total + commission).round(2)
      net_total = (net_total + net).round(2)

      producer = User.find(producer_id)
      creditor = producer.get_creditor

      payment_payable = PaymentPayable.new(amount: net.round(2), amount_paid: 0)        

      payment_payable.users << creditor

      for tote_item in value[:sub_tote]
        payment_payable.tote_items << tote_item
      end

      payment_payable.save

      num_payment_payables_created += 1

    end

    return num_payment_payables_created
    
  end

  private

    #returns a hash where key = producer id and value is a hash with keys/values for subtotevalue and subtotecommission.
    #this is a nominal commission, by the way
    def get_sub_tote_value_by_payment_sequenced_producer_id
      sub_totes_by_producer_id = get_sub_totes_by_producer_id      
      producer_id_payment_order = get_producer_id_payment_order(sub_totes_by_producer_id)

      sub_tote_value_by_payment_sequenced_producer_id = {}

      producer_id_payment_order.each do |producer_id|
        sub_tote = get_sub_tote(producer_id)        
        sub_tote_value = get_gross_tote(sub_tote, filled = true)        
        sub_tote_value_by_payment_sequenced_producer_id[producer_id] = { sub_tote: sub_tote, sub_tote_value: sub_tote_value }
      end

      return sub_tote_value_by_payment_sequenced_producer_id

    end

    #returns an array of producer ids in the order in which payments should be applied
    def get_producer_id_payment_order(sub_totes_by_producer_id)

      first_order_time_by_producer_id = {}

      sub_totes_by_producer_id.each do |producer_id, sub_tote|
        sorted_sub_tote = sub_tote.sort_by{|x| x.created_at}
        first_order_time_by_producer_id[producer_id] = sorted_sub_tote[0].created_at
      end      

      producer_id_payment_order_nested = first_order_time_by_producer_id.sort_by { |product_id, order_time| order_time }
      producer_id_payment_order = []

      producer_id_payment_order_nested.each do |x|
        producer_id_payment_order << x[0]        
      end      

      return producer_id_payment_order

    end

end