class BulkPurchase < ActiveRecord::Base
  include ToteItemsHelper
  attr_reader :num_payment_payables_created

  has_many :bulk_purchase_receivables
  has_many :purchase_receivables, through: :bulk_purchase_receivables

  def load_unpurchased_receivables  	
  	prs = PurchaseReceivable.load_unpurchased_purchase_receivables    
  	if prs &&  prs.any?
  	  for pr in prs
  	  	purchase_receivables << pr
  	  end
  	end    
  end

  def go

    @num_payment_payables_created = 0

  	if purchase_receivables && purchase_receivables.any?

  	  for purchase_receivable in purchase_receivables                
        purchase = purchase_receivable.purchase

        if purchase.response.success?
          #TODO: here we should probably check for purchase.response.success? and do something smart including notifying user there
          #was a payments problem
          self.gross = (self.gross + purchase.gross_amount).round(2)          
          self.payment_processor_fee_withheld_from_us = (self.payment_processor_fee_withheld_from_us + purchase.payment_processor_fee_withheld_from_us).round(2)

          sub_tote_value_by_payment_sequenced_producer_id = get_sub_tote_value_by_payment_sequenced_producer_id(purchase_receivable)
          create_payment_payables(purchase_receivable, purchase, sub_tote_value_by_payment_sequenced_producer_id)
          self.payment_processor_fee_withheld_from_producer = (self.payment_processor_fee_withheld_from_producer + purchase.payment_processor_fee_withheld_from_producer).round(2)
        else
          #not really sure what to do in this case, which is when the purchase fails
        end        

  	  end
  	  save
  	end    
  end

  private

    def create_payment_payables(purchase_receivable, purchase, sub_tote_value_by_payment_sequenced_producer_id)      

      amount_previously_purchased = purchase_receivable.amount_purchased - purchase.gross_amount
      gross_amount_payable = purchase.gross_amount

      #this cutoff amount var is an odd, but necessary duck. say you have a pr that collects funds to pay
      #to 4 different producers, each $20. but say the customer only pays 35 on the first purchase (for whatever
      #reason). this customer is going to have to make another future purchase to bring their account to zero.
      #when they make this second purchase we want to direct funds to the producers properly. in this example,
      #the first producer got maid whole, the second was partially paid and the last 2 weren't paid at all. so for
      #the second purchase we'd need to pay down the #2 producer and then pay off the last 2. the cutoff_amount
      #var tracks where the final amount to pay to farmer #2 is before switching to pay off #3 & #4.
      cutoff_amount = 0

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

        proportionally_share_payment_processor_fee_with_producer = 0

        if proportionally_share_payment_processor_fee_with_producer == 1
          payment_processor_effective_fee_factor = purchase.payment_processor_fee_withheld_from_us / purchase.gross_amount
          payment_processor_fee_withheld_from_producer = (gross_amount_payable_to_this_producer * payment_processor_effective_fee_factor).round(2)
        else
          #we're not going to proportionally share the processor fee. we're going to pass a flat amount on to them, sometimes
          #coming out ahead, sometimes behind. hopefully it all washes out on the average.
          payment_processor_fee_withheld_from_producer = (gross_amount_payable_to_this_producer * 0.035).round(2)          
        end

        purchase.payment_processor_fee_withheld_from_producer = (purchase.payment_processor_fee_withheld_from_producer + payment_processor_fee_withheld_from_producer).round(2)

        commission = (gross_amount_payable_to_this_producer * value[:sub_tote_commission_factor]).round(2)        
        net = gross_amount_payable_to_this_producer - payment_processor_fee_withheld_from_producer - commission
        
        self.commission = (self.commission + commission).round(2)
        self.net = (self.net + net).round(2)

        payment_payable = PaymentPayable.new(amount: net.round(2), amount_paid: 0)
        producer = User.find(producer_id)
        payment_payable.users << producer

        for tote_item in value[:sub_tote]
          payment_payable.tote_items << tote_item
        end

        payment_payable.save
        @num_payment_payables_created = @num_payment_payables_created + 1

      end
      purchase.save
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