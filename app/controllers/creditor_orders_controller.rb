class CreditorOrdersController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin
  before_action :get_creditor_order, only: [:show, :edit]

  def index
    @open_orders = CreditorOrder.joins(creditor: :business_interface).where(state: CreditorOrder.state(:OPEN)).order("business_interfaces.name").order(delivery_date: :asc)
    @closed_orders = CreditorOrder.joins(:postings).distinct.where(state: CreditorOrder.state(:CLOSED)).where("postings.delivery_date > ?", Time.zone.now.midnight - 8.weeks).order(delivery_date: :desc)
  end

  def show

    @payment_payables_sum = 0
    @payments_sum = 0

    if @creditor_order && @creditor_order.creditor_obligation
      @payment_payables_sum = @creditor_order.creditor_obligation.payment_payables.sum(:amount).round(2)
      @payments_sum = @creditor_order.creditor_obligation.payments.sum(:amount).round(2)
    end

  end

  def edit
  end

  def update

    fills = params[:fills]

    if fills.nil? || !fills.any?
      redirect_to creditor_orders_path
      return
    end

    fills.each do |fill|

      posting_id = fill[:posting_id].to_i

      if fill[:quantity].nil?
        quantity = nil
      else
        quantity = fill[:quantity].to_i
      end      

      if quantity.nil? || quantity < 0
        next
      end

      posting = Posting.find_by(id: posting_id)

      if posting.nil?
        next
      end      

      @fill_report = posting.fill(quantity)

    end

    @creditor_order = CreditorOrder.find_by(id: params[:id])

    if @creditor_order

      if @creditor_order.balanced? && @creditor_order.state?(:OPEN)
        #this condition was added in the case that a producer entirely skips delivering on an order. in this situation, as things currently are
        #the creditororder.transition method will never get called so the co stays in the OPEN state. fix that.
        @creditor_order.transition(:skipped_delivery)
      end

      redirect_to creditor_order_path(@creditor_order)

    else
      flash[:danger] = "Couldn't find CreditorOrder id: #{params[:id].to_s}"
      redirect_to creditor_orders_path
    end    

  end

  def new
  end

  def create
  end

  def destroy
  end

  private
    def get_creditor_order
      @creditor_order = CreditorOrder.find_by(id: params[:id])

      if @creditor_order.nil?
        redirect_to root_path
      end      
    end

end