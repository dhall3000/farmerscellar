class BulkPurchase < ActiveRecord::Base
  include ToteItemsHelper
  attr_reader :num_payment_payables_created, :admin_report

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

    puts "BulkPurchase.go start"

    @num_payment_payables_created = 0

    total_amount_of_failed_purchases = 0
    failed_purchases = []
    
    total_amount_of_underamount_purchases = 0
    underamount_purchases = []    

  	if purchase_receivables && purchase_receivables.any?

  	  for purchase_receivable in purchase_receivables

        s = JunkCloset.puts_helper("Now executing purchase...", "user", purchase_receivable.users.last.email)
        s = JunkCloset.puts_helper(s, "PurchaseReceivable id", purchase_receivable.id.to_s)
        s = JunkCloset.puts_helper(s, "amount", number_to_currency(purchase_receivable.amount))
        s = JunkCloset.puts_helper(s, "amount_purchased", number_to_currency(purchase_receivable.amount_purchased))
        puts s

        purchase = purchase_receivable.purchase

        if purchase.response.success?

          puts JunkCloset.puts_helper("Purchase success.", "gross_amount", number_to_currency(purchase.gross_amount))

          self.gross = (self.gross + purchase.gross_amount).round(2)          
          self.payment_processor_fee_withheld_from_us = (self.payment_processor_fee_withheld_from_us + purchase.payment_processor_fee_withheld_from_us).round(2)          
          create_payment_payables(purchase_receivable, purchase)
          self.payment_processor_fee_withheld_from_producer = (self.payment_processor_fee_withheld_from_producer + purchase.payment_processor_fee_withheld_from_producer).round(2)

          if purchase.gross_amount < purchase_receivable.amount_to_capture
            underamount = (purchase_receivable.amount_to_capture - purchase.gross_amount).round(2)
            puts JunkCloset.puts_helper("Purchase underamount.", "underamount", number_to_currency(underamount))
            total_amount_of_underamount_purchases = (total_amount_of_underamount_purchases + underamount).round(2)
            underamount_purchases << purchase
          end

        else
          puts JunkCloset.puts_helper("Purchase failure.", "amount_to_capture", number_to_currency(purchase_receivable.amount_to_capture))
          total_amount_of_failed_purchases = (total_amount_of_failed_purchases + purchase_receivable.amount_to_capture).round(2)
          failed_purchases << purchase
        end

  	  end
  	  save
  	end

    create_admin_report(total_amount_of_failed_purchases, total_amount_of_underamount_purchases, failed_purchases)
    puts "---BULKPURCHASE ADMIN REPORT START---"
    dump_admin_report_to_log
    puts "---BULKPURCHASE ADMIN REPORT END---"
    puts "BulkPurchase.go end"

  end

  private

    def dump_admin_report_to_log

      @admin_report.each do |line|
        puts line
      end

    end

    def create_admin_report(total_amount_of_failed_purchases, total_amount_of_underamount_purchases, failed_purchases)

      @admin_report = []

      @admin_report << JunkCloset.puts_helper("", "BulkPurchase id", id.to_s) + " report:"
      @admin_report << JunkCloset.puts_helper("", "gross", gross.to_s)    
      @admin_report << JunkCloset.puts_helper("", "net", net.to_s)
      @admin_report << JunkCloset.puts_helper("", "payment_processor_fee_withheld_from_producer", payment_processor_fee_withheld_from_producer.to_s)
      @admin_report << JunkCloset.puts_helper("", "payment_processor_fee_withheld_from_us", payment_processor_fee_withheld_from_us.to_s)    
      @admin_report << JunkCloset.puts_helper("", "net on payment processor fees", (payment_processor_fee_withheld_from_producer - payment_processor_fee_withheld_from_us).round(2).to_s)    
      @admin_report << JunkCloset.puts_helper("", "commission", commission.to_s)
      @admin_report << JunkCloset.puts_helper("", "sales", (gross - payment_processor_fee_withheld_from_us - net).round(2).to_s)

      if total_amount_of_failed_purchases > 0

        @admin_report << JunkCloset.puts_helper("", "total_amount_of_failed_purchases", total_amount_of_failed_purchases.to_s)
        failed_purchases.each do |purchase|
          s = JunkCloset.puts_helper("", "Failed Purchase id", purchase.id.to_s)
          s = JunkCloset.puts_helper(s, "amount to capture", purchase.amount_to_capture.to_s)
          s = JunkCloset.puts_helper(s, "gross amount", purchase.gross_amount.to_s)
          @admin_report << s
        end

      end

      if total_amount_of_underamount_purchases > 0

        @admin_report << JunkCloset.puts_helper("", "total_amount_of_underamount_purchases", total_amount_of_underamount_purchases.to_s)
        underamount_purchases.each do |purchase|
          s = JunkCloset.puts_helper("", "Underamount Purchase id", purchase.id.to_s)
          s = JunkCloset.puts_helper(s, "amount to capture", purchase.amount_to_capture.to_s)
          s = JunkCloset.puts_helper(s, "gross amount", purchase.gross_amount.to_s)
          @admin_report << s
        end      

      end      

    end

    def create_payment_payables(purchase_receivable, purchase)      

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

      sub_tote_value_by_payment_sequenced_producer_id = get_sub_tote_value_by_payment_sequenced_producer_id(purchase_receivable)
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

        purchase.payment_processor_fee_withheld_from_producer = (purchase.payment_processor_fee_withheld_from_producer + get_payment_processor_fee_tote(value[:sub_tote])).round(2)
        commission = get_commission_tote(value[:sub_tote])
        net = get_producer_net_tote(value[:sub_tote])
        
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
        sub_tote_value = get_gross_tote(sub_tote)        
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