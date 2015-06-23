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

        #TODO: tote_item.update(status: ToteItem.states[:PURCHASED])

        #net_towards_producer_after_payments_fees = gross_amount_payable_to_this_producer * (1.0 - payment_processor_effective_fee_factor)
        #net_towards_producer_after_commission = net_towards_producer_after_payments_fees * (1.0 - value.sub_tote_commission_factor)

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
        sub_tote_value_by_payment_sequenced_producer_id[producer_id] = { sub_tote_value: sub_tote_value, sub_tote_commission_factor: sub_tote_commission_factor }
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

    def create_payment_payable(purchase)
      if response.success?
        previously_paid = amount_paid
        update(amount_paid: gross_amount + previously_paid)

        net_reduction_factor = 1.0 - (net_amount / gross_amount)
        #for each tote_item:
          #1) change toteitems' states to PURCHASED
          #2) create a new PaymentPayable record
        tote_items.each do |tote_item|
          tote_item.update(status: ToteItem.states[:PURCHASED])
          tote_item_purchase_amount = tote_item.quantity * tote_item.price
          net_after_payment_fees = tote_item_purchase_amount * net_reduction_factor
          product_id = tote_item.posting.product_id
          producer_id = tote_item.posting.user_id
          #farmers_cellar_commission_factor = tote_item.posting.product.producer_product_commissions.where(product_id: product_id, user_id: producer_id).last
          #farmers_cellar_commission = farmers_cellar_commission_factor * net_after_payment_fees
          #producer_sales = net_after_payment_fees - @farmers_cellar_commission
          #TODO: record farmers_cellar_commission in FC master sales table
          #tote_item.payment_payables.create(amount: producer_sales, amount_paid: 0)
          #payment_payable = tote_item.payment_payables.last
          #payment_payable.users << User.find(producer_id)
          #payment_payable.save
        end                    
      else    
        #TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed
        #and that their account is now on hold
      end        
    end
end