require 'utility/bulk_payment_processing'

class BulkPaymentsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def new

    values = BulkPaymentProcessing.bulk_payment_new

    if values != nil
      @unpaid_payment_payables = values[:unpaid_payment_payables]
      @grand_total_payout = values[:grand_total_payout]
      @payment_info_by_creditor_id = values[:payment_info_by_creditor_id]
    end

  end

  def create    

    values = BulkPaymentProcessing.bulk_payment_create(params)

    @messages = values[:messages]
    @payment_info_by_producer_id = values[:payment_info_by_creditor_id]
    @num_payees = values[:num_payees]
    @cumulative_total_payout = values[:cumulative_total_payout]
    @bulk_payment = values[:bulk_payment]    
    @payment_invoice_infos = values[:payment_invoice_infos]

  end

  def test_masspay

  end

end