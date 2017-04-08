require 'integration_helper'

class PaymentPayablesControllerTest < IntegrationHelper

  def setup

    creditor = users(:f1)
    creditor.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CHECK])
    pp = PaymentPayable.new(amount: 10.55, amount_paid: 0)
    pp.users << creditor
    pp.save
    pp = PaymentPayable.new(amount: 30.45, amount_paid: 0)
    pp.users << creditor
    pp.save

    creditor = users(:f2)
    creditor.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CASH])
    pp = PaymentPayable.new(amount: 20.35, amount_paid: 0)
    pp.users << creditor
    pp.save
    pp = PaymentPayable.new(amount: 40.65, amount_paid: 0)
    pp.users << creditor
    pp.save

    @admin = users(:a1)

  end

  test "should get index" do
    log_in_as @admin
    get payment_payables_path
    assert :success
    assert_template 'payment_payables/index'
    pps_by_creditor = assigns(:pps_by_creditor)
    assert_equal 2, pps_by_creditor.count
    assert_select 'td', {text: "Check", count: 1}
    assert_select 'td', {text: "Cash", count: 1}
  end

  test "should get index for creditor" do
    log_in_as @admin
    f1 = users(:f1)
    get payment_payables_path, params: {creditor_id: f1.id}
    assert :success
    assert_template 'payment_payables/creditor_index'
    assert_equal 2, assigns(:unpaid_payment_payables).count
    assert_equal 41.0, assigns(:total)
  end

end