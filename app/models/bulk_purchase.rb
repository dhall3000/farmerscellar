class BulkPurchase < ApplicationRecord
  include ToteItemsHelper
  attr_reader :num_payment_payables_created, :admin_report

  has_many :bulk_purchase_receivables
  has_many :purchase_receivables, through: :bulk_purchase_receivables

  def load_unpurchased_receivables_for_users(users)
  	prs = PurchaseReceivable.load_unpurchased_purchase_receivables_for_users(users)
  	if prs &&  prs.any?
  	  for pr in prs
  	  	purchase_receivables << pr
  	  end
  	end    
  end

  def go

    puts "BulkPurchase.go start"

  	if purchase_receivables && purchase_receivables.any?            

      @num_payment_payables_created = 0
      @total_amount_of_failed_purchases = 0
      @failed_purchases = []      
      @total_amount_of_underamount_purchases = 0
      @under_amount_purchases = []      
      
      prs_by_auth = {}
      prs_by_rtauth = {}

      #there's one pr for every tote_item. loop through and batch them up according to authorization
      #so that we can batch purchases and not get overly dinged by payment processor transaction fees
      purchase_receivables.each do |pr|

        if rtauth = pr.tote_items.order("tote_items.id").first.rtauthorization

          if !prs_by_rtauth.has_key?(rtauth)
            prs_by_rtauth[rtauth] = []
          end

          prs_by_rtauth[rtauth] << pr

        elsif auth = pr.tote_items.order("tote_items.id").first.authorization            

          if !prs_by_auth.has_key?(auth)
            prs_by_auth[auth] = []
          end

          prs_by_auth[auth] << pr

        else
          #there is a problem here. a pr doesn't have an authorization. this will result in a failure to collect funds which will result
          #in a failure to pay a farmer. send an email to admin here so we know about it right off the bat          
          msg_body = "BulkPurchase.go could not find an authorization for PurchaseReceivable ID #{pr.id.to_s}. This means that no attempt will be made to capture funds for the tote items therein associated. The customer's purchase receipt will say 'PURCHASEFAILED'. The farmer also won't get paid for this pr. An admin should begin an investigation on this matter ASAP."
          AdminNotificationMailer.general_message("BulkPurchase error", msg_body).deliver_now
        end

      end

      #loop through the authorizations and create a single purchase for each one, based off the associated group of purchase receivables
      prs_by_auth.each do |authorization, prs|
        purchase = Purchase.new(payment_processor_fee_withheld_from_producer: 0)
        purchase.go(authorization, prs)
        after_purchase(purchase, prs)
        purchase.save        
      end

      prs_by_rtauth.each do |rtauth, prs|
        rtpurchase = Rtpurchase.new(payment_processor_fee_withheld_from_producer: 0)
        rtpurchase.go(rtauth, prs)
        after_purchase(rtpurchase, prs)
        rtpurchase.save
      end

  	end

    save

    create_admin_report(@total_amount_of_failed_purchases, @total_amount_of_underamount_purchases, @failed_purchases, @under_amount_purchases)
    puts "---BULKPURCHASE ADMIN REPORT START---"
    dump_admin_report_to_log
    puts "---BULKPURCHASE ADMIN REPORT END---"

    puts "BulkPurchase.go end"

  end

  def do_bulk_email_communication
    send_purchase_receipts
    send_admin_report
  end

  private

    def after_purchase(purchase, prs)

      if purchase.success?
        self.payment_processor_fee_withheld_from_us = (self.payment_processor_fee_withheld_from_us + purchase.payment_processor_fee_withheld_from_us).round(2)
        self.gross = (self.gross + purchase.gross_amount).round(2)

        prs.each do |pr|
          create_payment_payables(pr, purchase)      
        end

        self.payment_processor_fee_withheld_from_producer = (self.payment_processor_fee_withheld_from_producer + purchase.payment_processor_fee_withheld_from_producer).round(2)

        if purchase.gross_amount < purchase.amount_to_capture
          underamount = (purchase.amount_to_capture - purchase.gross_amount).round(2)
          puts "Purchase underamount: #{underamount.to_s}"
          @total_amount_of_underamount_purchases = (@total_amount_of_underamount_purchases + underamount).round(2)
          @underamount_purchases << purchase
        end

      else
        #put this user's account on hold so they can't order again until they clear up this failed purchase                
        UserAccountState.add_new_state(purchase.user, :HOLD, "purchase failed")        
        puts "Purchase failure: #{purchase.amount_to_capture.to_s}"
        @total_amount_of_failed_purchases = (@total_amount_of_failed_purchases + purchase.amount_to_capture).round(2)
        @failed_purchases << purchase
      end

    end

    def send_admin_report

      puts "BulkPurchase.send_admin_report start"

      body = ""

      admin_report.each do |line|
        body += ". " + line
      end

      AdminNotificationMailer.general_message("bulk purchase report", body).deliver_now      
      
      puts "sent bulk purchase report email to david@farmerscellar.com"
      puts "BulkPurchase.send_admin_report end"

    end

    def send_purchase_receipts

      puts "BulkPurchase.send_purchase_receipts start"

      tote_items_by_user = get_tote_items_by_user

      tote_items_by_user.each do |user, tote_items|                
        UserMailer.purchase_receipt(user, tote_items).deliver_now
        puts "sent purchase receipt email to " + user.email
      end

      puts "BulkPurchase.send_purchase_receipts end"

    end

    def get_tote_items_by_user
      
      tote_items_by_user = {}

      purchase_receivables.each do |pr|
        pr.tote_items.each do |tote_item|
          if !tote_items_by_user.has_key?(tote_item.user)
            tote_items_by_user[tote_item.user] = []
          end
          tote_items_by_user[tote_item.user] << tote_item
        end
      end

      return tote_items_by_user

    end

    def dump_admin_report_to_log

      @admin_report.each do |line|
        puts line
      end

    end

    def create_admin_report(total_amount_of_failed_purchases, total_amount_of_underamount_purchases, failed_purchases, under_amount_purchases)

      @admin_report = []

      @admin_report << "BulkPurchase id: #{id.to_s} report:"
      @admin_report << "gross #{gross.to_s}"
      @admin_report << "net #{net.to_s}"
      @admin_report << "payment_processor_fee_withheld_from_producer #{payment_processor_fee_withheld_from_producer.to_s}"
      @admin_report << "payment_processor_fee_withheld_from_us #{payment_processor_fee_withheld_from_us.to_s}"
      @admin_report << "net on payment processor fees #{(payment_processor_fee_withheld_from_producer - payment_processor_fee_withheld_from_us).round(2).to_s}" 
      @admin_report << "commission #{commission.to_s}"
      @admin_report << "sales #{(gross - payment_processor_fee_withheld_from_us - net).round(2).to_s}"

      if total_amount_of_failed_purchases > 0

        @admin_report << "total_amount_of_failed_purchases #{total_amount_of_failed_purchases.to_s}"
        failed_purchases.each do |purchase|
          s = "Failed Purchase id #{purchase.id.to_s}"
          s = s + " amount to capture #{purchase.amount_to_capture.to_s}"
          s = s + " gross amount #{purchase.gross_amount.to_s}"
          @admin_report << s
        end

      end

      if total_amount_of_underamount_purchases > 0

        @admin_report << "total_amount_of_underamount_purchases #{total_amount_of_underamount_purchases.to_s}"
        underamount_purchases.each do |purchase|
          s = "Underamount Purchase id #{purchase.id.to_s}"
          s = s + " amount to capture #{purchase.amount_to_capture.to_s}"
          s = s + " gross amount #{purchase.gross_amount.to_s}"
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

        purchase.payment_processor_fee_withheld_from_producer = (purchase.payment_processor_fee_withheld_from_producer + get_payment_processor_fee_tote(value[:sub_tote], filled = true)).round(2)
        commission = get_commission_tote(value[:sub_tote], filled = true)
        net = get_producer_net_tote(value[:sub_tote], filled = true)
        
        self.commission = (self.commission + commission).round(2)
        self.net = (self.net + net).round(2)

        producer = User.find(producer_id)
        creditor = producer.get_creditor
        creditor_settings = creditor.settings

        if creditor_settings.conditional_payment

          payment_payable = PaymentPayable.new(amount: net.round(2), amount_paid: 0)        

          payment_payable.users << creditor

          for tote_item in value[:sub_tote]
            payment_payable.tote_items << tote_item
          end

          payment_payable.save

        end

        @num_payment_payables_created = @num_payment_payables_created + 1

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