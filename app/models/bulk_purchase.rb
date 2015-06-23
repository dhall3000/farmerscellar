class BulkPurchase < ActiveRecord::Base
  include ToteItemsHelper
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
        purchase = purchase_receivable.purchase

        #TODO: here we should probably check for purchase.response.success? and do something smart including notifying user there
        #was a payments problem
        
        sub_tote_value_by_payment_sequenced_producer_id = get_sub_tote_value_by_payment_sequenced_producer_id(purchase_receivable)
        create_payment_payables(purchase_receivable, purchase, sub_tote_value_by_payment_sequenced_producer_id)

        #producers_ids = purchase_receivable.get_producer_ids
        #sub_totes = 
        #create_payment_payable(purchase)
  	  end
  	  save
  	end    
  end

  private

    def create_payment_payables(purchase_receivable, purchase, sub_tote_value_by_payment_sequenced_producer_id)

      #amount_paid_prior_to_this_purchase

      amount_already_paid = purchase_receivable.amount_paid - purchase.gross_amount
      gross_amount_payable = purchase.gross_amount
      cutoff_amount = 0

      sub_tote_value_by_payment_sequenced_producer_id.each do |producer_id, value|

        if gross_amount_payable <= 0
          next
        end

        cutoff_amount += value[:sub_tote_value]
        if amount_already_paid > cutoff_amount
          next
        end

        amount_remaining_to_pay_to_this_producer = cutoff_amount - amount_already_paid
        gross_amount_payable_to_this_producer = [gross_amount_payable, amount_remaining_to_pay_to_this_producer].min
        amount_already_paid += gross_amount_payable_to_this_producer
        gross_amount_payable -= gross_amount_payable_to_this_producer

        payment_processor_effective_fee_factor = purchase.fee_amount / purchase.gross_amount
        payment_processor_fee = gross_amount_payable_to_this_producer * payment_processor_effective_fee_factor
        net_after_payment_processor_fee = gross_amount_payable_to_this_producer - payment_processor_fee
        commission = net_after_payment_processor_fee * value[:sub_tote_commission_factor]
        net_after_commission = net_after_payment_processor_fee - commission

        payment_payable = PaymentPayable.new(amount: net_after_commission, amount_paid: 0)
        producer = User.find(producer_id)
        payment_payable.users << producer

        for tote_item in value[:sub_tote]
          payment_payable.tote_items << tote_item
        end

        payment_payable.save

      end
    end

    #returns a hash where key = producer id and value is a hash with keys/values for subtotevalue and subtotecommission.
    #this is a nominal commission, by the way
    def get_sub_tote_value_by_payment_sequenced_producer_id(purchase_receivable)
      sub_totes_by_producer_id = purchase_receivable.get_sub_totes_by_producer_id      
      producer_id_payment_order = get_producer_id_payment_order(sub_totes_by_producer_id)

      sub_tote_value_by_payment_sequenced_producer_id = {}

      producer_id_payment_order.each do |producer_id|
        sub_tote = purchase_receivable.get_sub_tote(producer_id)        
        sub_tote_value = total_cost_of_tote_items(sub_tote)                
        sub_tote_commission_factor = get_commission_factor(sub_tote)
        sub_tote_value_by_payment_sequenced_producer_id[producer_id] = { sub_tote: sub_tote, sub_tote_value: sub_tote_value, sub_tote_commission_factor: sub_tote_commission_factor }
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