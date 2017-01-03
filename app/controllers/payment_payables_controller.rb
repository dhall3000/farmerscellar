class PaymentPayablesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def index

    creditor_id = params[:creditor_id]

    if creditor_id.nil?
      #pulls up list of unpaid creditors and shows total amount due
      #if no creditor id param fetch summary data
      @pps_by_creditor = get_pps_by_creditor
      render 'index'
    else
      #pulls up list of unpaid PPs for given creditor and shows total amount due
      #if creditor id param fetch / display pp's just for that user
      @creditor = User.find(creditor_id.to_i)
      @unpaid_payment_payables = PaymentPayable.joins(:users).where(fully_paid: false).where("users.id = ?", @creditor.id)
      @total = @unpaid_payment_payables.sum("amount - amount_paid")
      render 'creditor_index'
    end
    
  end

  private
  
    def get_pps_by_creditor

      pps_by_creditor = {}

      pps = PaymentPayable.where(fully_paid: false)

      pps.each do |pp|

        creditor = pp.users.last
        
        if pps_by_creditor[creditor].nil?
          pps_by_creditor[creditor] = 0.0
        end

        pps_by_creditor[creditor] = (pps_by_creditor[creditor] + (pp.amount - pp.amount_paid)).round(2)

      end

      return pps_by_creditor

    end

    def dev_create_db_objects

      creditor = User.find_by(email: "f1@f.com")
      creditor.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CHECK])

      if UserPaymentPayable.where(user: creditor).count > 0
        UserPaymentPayable.all.delete_all
        PaymentPayable.all.delete_all
      end

      pp = PaymentPayable.new(amount: 10.55, amount_paid: 0)
      pp.users << creditor
      pp.save
      pp = PaymentPayable.new(amount: 30.45, amount_paid: 0)
      pp.users << creditor
      pp.save

      creditor = User.find_by(email: "f2@f.com")
      creditor.get_business_interface.update(payment_method: BusinessInterface.payment_methods[:CHECK])
      pp = PaymentPayable.new(amount: 20.35, amount_paid: 0)
      pp.users << creditor
      pp.save
      pp = PaymentPayable.new(amount: 40.65, amount_paid: 0)
      pp.users << creditor
      pp.save

    end

end