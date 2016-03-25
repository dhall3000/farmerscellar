require 'utility/bulk_payment_processing'

class BulkPaymentsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new

    values = BulkPaymentProcessing.bulk_payment_new

    if values != nil
      @unpaid_payment_payables = values[:unpaid_payment_payables]
      @grand_total_payout = values[:grand_total_payout]
      @payment_info_by_producer_id = values[:payment_info_by_producer_id]
    end

  end

  def create    

    values = BulkPaymentProcessing.bulk_payment_create(params)

    @messages = values[:messages]
    @payment_info_by_producer_id = values[:payment_info_by_producer_id]
    @num_payees = values[:num_payees]
    @cumulative_total_payout = values[:cumulative_total_payout]
    @bulk_payment = values[:bulk_payment]    
    @payment_invoice_infos = values[:payment_invoice_infos]

  end

  def test_masspay

  end

end

class FakeMasspayResponse
  attr_reader :body
  def initialize
    @body = "TIMESTAMP=2011%2d11%2d15T20%3a27%3a02Z&CORRELATIONID=5be53331d9700&ACK=Failure&VERSION=78%2e0&BUILD=000000&L_ERRORCODE0=15005&L_SHORTMESSAGE0=Processor%20Decline&L_LONGMESSAGE0=This%20transaction%20cannot%20be%20processed%2e&L_SEVERITYCODE0=Error&L_ERRORPARAMID0=ProcessorResponse&L_ERRORPARAMVALUE0=0051&AMT=10%2e40&CURRENCYCODE=USD&AVSCODE=X&CVV2MATCH=M"
  end
end