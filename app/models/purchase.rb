class Purchase < ActiveRecord::Base  
  attr_reader :amount_to_capture
  serialize :response

  has_many :purchase_purchase_receivables
  has_many :purchase_receivables, through: :purchase_purchase_receivables    

  def success?
    response.success?
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

  def go(authorization, prs)

    puts "Purchase.go start"

    @amount_to_capture = 0

    prs.each do |pr|
      purchase_receivables << pr
      amount = (pr.amount - pr.amount_purchased).round(2)
      @amount_to_capture = (@amount_to_capture + amount).round(2)
    end

    amount_to_capture_in_cents = (@amount_to_capture * 100).round(2)
    
    if USEGATEWAY
      self.response = GATEWAY.capture(amount_to_capture_in_cents, authorization.transaction_id, complete_type: "NotComplete")
    else
      self.response = FakeCaptureResponse.new(amount_to_capture_in_cents, authorization.transaction_id)
    end
        
    self.transaction_id = response.params["transaction_id"]
    self.payer_id = authorization.payer_id
    self.gross_amount = response.params["gross_amount"].to_f.round(2)
    self.payment_processor_fee_withheld_from_us = response.params["fee_amount"].to_f.round(2)
    self.net_amount = (gross_amount - payment_processor_fee_withheld_from_us).round(2)

    if response.success?

      #apply purchase amount to purchase receivables
          
      purchase_gross_amount_remaining = gross_amount

      purchase_receivables.each do |pr|
        
        if pr.amount_outstanding <= purchase_gross_amount_remaining
          pr.apply(pr.amount_outstanding)                    
          purchase_gross_amount_remaining = (purchase_gross_amount_remaining - pr.amount_outstanding).round(2)
        end
      end

      authorization.amount_purchased = (authorization.amount_purchased + self.gross_amount).round(2)
      authorization.save

    else
      purchase_receivables.each do |pr|
        PurchaseReceivable.transition(:purchase_failed, {purchase_receivables: [pr]})  
      end
    end    

    s = JunkCloset.puts_helper("", "@amount_to_capture", number_to_currency(@amount_to_capture))
    s = JunkCloset.puts_helper(s, "gross_amount", number_to_currency(gross_amount))
    s = JunkCloset.puts_helper(s, "net_amount", number_to_currency(net_amount))
    puts s

    puts "Purchase.go end"

  end

end

class FakeCaptureResponse
  attr_reader :params

  @@toggle_success = false
  @@succeed = true

  def self.toggle_success=val
    @@toggle_success=val
  end

  def self.succeed=val
    @@succeed=val
  end

  def initialize(amount_in_cents, authorization_transaction_id)

    percentage = 0.029
    flat_fee = 0.3

    if @@toggle_success      
      @@succeed = !@@succeed
    end
      
    if @@succeed      
      fee_amount = (((amount_in_cents * percentage) / 100) + flat_fee).round(2)
      ack = "Success"      
    else      
      amount_in_cents = 0      
      fee_amount = 0
      ack = "Failure"      
    end        

    @success = @@succeed

    @params = {
      "transaction_id" => authorization_transaction_id,
      "gross_amount" => (amount_in_cents / 100).to_s,
      "fee_amount" => fee_amount.to_s,
      "ack" => ack
    }

  end

  def success?
    @success
  end
end