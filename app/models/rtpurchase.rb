class Rtpurchase < ActiveRecord::Base
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
      return purchase_receivables.first.users.last
    end

    return nil

  end  

  def go(rtauthorization, prs)

    puts "Rturchase.go start"

    @amount_to_capture = 0

    prs.each do |pr|
      purchase_receivables << pr
      amount = (pr.amount - pr.amount_purchased).round(2)
      @amount_to_capture = (@amount_to_capture + amount).round(2)
    end

    amount_to_capture_in_cents = (@amount_to_capture * 100).round(2)
    
    if USEGATEWAY

      if rtauthorization.rtba.ba_valid?
        response = GATEWAY.reference_transaction(amount_to_capture_in_cents, reference_id: rtauthorization.rtba.ba_id, currency: 'USD')
      end
          
    else      
      response = FakeRtpurchaseResponseSuccess.new
    end

    if response
      self.success = response.success?
      self.message = response.message
      self.correlation_id = response.params["correlation_id"]
      self.transaction_id = response.params["transaction_id"]
      self.ba_id = response.params["billing_agreement_id"]
      self.gross_amount = response.params["gross_amount"].to_f.round(2)
      self.payment_processor_fee_withheld_from_us = response.params["fee_amount"].to_f.round(2)      
      self.ack = response.params["ack"]

      #this is correct. when purchase succeeds there won't be an "error_codes" value in the response so we'll just be writing
      #nil to the database. if you want to see an example of this look in file 'referenceTransactionResponses.txt' for this:
      #"error_codes"=>"10201"
      #there's actually 2 instances of that string in that file. the 2nd one is of interest.
      self.error_code = response.params["error_codes"]      
    else

    end

    if success?

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
    end    

    puts "@amount_to_capture: #{@amount_to_capture.to_s}, gross_amount: #{gross_amount}"    
    puts "Rturchase.go end"

    save

  end

end

class FakeRtpurchaseResponseSuccess
  attr_reader :params

  def initialize

    @params = {
      "correlation_id" => "correlation_id",
      "billing_agreement_id" => "billing_agreement_id",
      "gross_amount" => "21.24",
      "fee_amount" => "0.63",
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