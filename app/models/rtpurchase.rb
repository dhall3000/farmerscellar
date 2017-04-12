class Rtpurchase < ApplicationRecord
  attr_reader :amount_to_capture
	has_many :rtpurchase_prs
	has_many :purchase_receivables, through: :rtpurchase_prs

	validates_presence_of :purchase_receivables
	validates :message, :correlation_id, presence: true

  def success?    
    success
  end

  def user

    if purchase_receivables.nil?
      return nil
    end

    if purchase_receivables.any?

      #you can't make the .order call below with an uncreated self object
      if id.nil?
        save
      end

      return purchase_receivables.order("purchase_receivables.id").first.users.order("users.id").last

    end

    return nil

  end  

  def go(rtauthorization, prs)

    puts "Rturchase.go start"

    @amount_to_capture = 0
    tote_items = []

    prs.each do |pr|
      pr.tote_items.each do |ti|
        tote_items << ti
      end
      purchase_receivables << pr
      amount = (pr.amount - pr.amount_purchased).round(2)
      @amount_to_capture = (@amount_to_capture + amount).round(2)
    end    

    amount_to_capture_in_cents = (@amount_to_capture * 100).round(2)
    items = ToteItemsController.helpers.get_order_summary_details_for_paypal_display(tote_items)
    
    if USEGATEWAY
      response = GATEWAY.reference_transaction(amount_to_capture_in_cents, reference_id: rtauthorization.rtba.ba_id, currency: 'USD', items: items)
    else      
      response = FakeRtpurchaseResponseSuccess.new(@amount_to_capture)      
    end

    self.transaction_id = response.params["transaction_id"]
    self.success = response.success?
    self.gross_amount = response.params["gross_amount"].to_f.round(2)
    self.payment_processor_fee_withheld_from_us = response.params["fee_amount"].to_f.round(2)      
    self.message = response.message
    self.correlation_id = response.params["correlation_id"]    
    self.ba_id = response.params["billing_agreement_id"]        
    self.ack = response.params["ack"]

    #this is correct. when purchase succeeds there won't be an "error_codes" value in the response so we'll just be writing
    #nil to the database. if you want to see an example of this look in file 'referenceTransactionResponses.txt' for this:
    #"error_codes"=>"10201"
    #there's actually 2 instances of that string in that file. the 2nd one is of interest.
    self.error_codes = response.params["error_codes"]      

    if success?

      save #this save has to be here otherwise this line returns zero items:
      #tote_items = ToteItem.joins(:purchase_receivables).where(purchase_receivables: {id: purchase_receivables}).distinct
      #and if that happens then self.payment_processor_fee_withheld_from_producer evaluates to $0
      tote_items = ToteItem.joins(:purchase_receivables).where(purchase_receivables: {id: purchase_receivables}).distinct
      
      payment_processor_fee_tote = ToteItemsController.helpers.get_payment_processor_fee_tote(tote_items, filled = true)    
      self.payment_processor_fee_withheld_from_producer = payment_processor_fee_tote

      #apply purchase amount to purchase receivables
          
      purchase_gross_amount_remaining = gross_amount

      purchase_receivables.each do |pr|
        
        if pr.amount_outstanding <= purchase_gross_amount_remaining
          pr.apply(pr.amount_outstanding)                    
          purchase_gross_amount_remaining = (purchase_gross_amount_remaining - pr.amount_outstanding).round(2)
        end
      end

    else
   
      purchase_receivables.each do |pr|
        PurchaseReceivable.transition(:purchase_failed, {purchase_receivables: [pr]})  
      end

      #TODO:
      #-invalidate the rtba / rtauth?
      #-put user account on hold?

    end    

    puts "@amount_to_capture: #{@amount_to_capture.to_s}, gross_amount: #{gross_amount}"    
    puts "Rturchase.go end"

    save

  end

end

class FakeRtpurchaseResponseSuccess
  attr_reader :params

  def initialize(amount_to_capture)

    percentage = 0.029
    flat_fee = 0.3
    fee_amount = ((amount_to_capture * percentage) + flat_fee).round(2)

    @params = {
      "correlation_id" => "correlation_id",
      "billing_agreement_id" => "billing_agreement_id",
      "gross_amount" => amount_to_capture.to_s,
      "fee_amount" => fee_amount.to_s,
      "ack" => "Success",
      "transaction_id" => "transaction_id"
    }

  end

  def success?
    true
  end

  def message
    "Success"
  end

end