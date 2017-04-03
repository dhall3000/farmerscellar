class PaymentsController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def index
    
  end

  def new
    @creditor_order = CreditorOrder.find_by(id: creditor_params[:creditor_order_id].to_i)
    balance = 0
    if @creditor_order
      balance = @creditor_order.balance
      if @creditor_order.creditor
        @business_interface = @creditor_order.creditor.get_business_interface
      end      
    end
    @payment = Payment.new(amount: balance, amount_applied: 0)
  end

  def create

    @payment = Payment.create(payment_params)

    if !@payment.valid?
      flash.now[:danger] = "Payment not saved"
      render 'payments/new'
      return
    end

    flash[:success] = "Payment ##{@payment.id.to_s} of #{ActiveSupport::NumberHelper.number_to_currency(@payment.amount)} created"
    @creditor_order = CreditorOrder.find_by(id: creditor_params[:creditor_order_id].to_i)

    if @creditor_order
      @creditor_order.add_payment(@payment)
      if @creditor_order.business_interface.payment_receipt_email
        ProducerNotificationsMailer.payment_receipt(@creditor_order, @payment).deliver_now
      end
      redirect_to creditor_order_path(@creditor_order)
      return
    end    

  end

  private

    def creditor_params
      params.permit(:creditor_order_id)
    end

    def payment_params
      return params.require(:payment).permit(:amount, :amount_applied, :notes)
    end

end
