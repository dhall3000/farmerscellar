class Purchase < ActiveRecord::Base
  serialize :response

  has_many :purchase_purchase_receivables
  has_many :purchase_receivables, through: :purchase_purchase_receivables    

  def go(amount_to_capture_in_cents, authorization_payer_id, authorization_transaction_id)
    if USEGATEWAY
      self.response = GATEWAY.capture(amount_to_capture_in_cents, authorization_transaction_id)
    else
      self.response = FakeCaptureResponse.new(amount_to_capture_in_cents, authorization_transaction_id)
    end
        
    self.transaction_id = response.params["transaction_id"]
    self.payer_id = authorization_payer_id
    self.gross_amount = response.params["gross_amount"].to_f.round(2)
    self.fee_amount = response.params["fee_amount"].to_f.round(2)
    self.net_amount = (gross_amount - fee_amount).round(2)
    
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

    percentage = 0.035
    fee_amount = (amount_in_cents * percentage / 100).round(2)

    if @@toggle_success      
      @@succeed = !@@succeed
    end
      
    if @@succeed
      ack = "Success"      
    else
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