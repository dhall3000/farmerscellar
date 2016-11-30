class CreditorOrdersController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def index
    @creditor_orders = CreditorOrder.where("delivery_date > ?", Time.zone.now - 6.weeks).order(delivery_date: :asc)
    split = split_on_closed_postings(@creditor_orders)
    @unclosed_creditor_orders = split[:unclosed_creditor_orders]
    @closed_creditor_orders = split[:closed_creditor_orders]
  end

  def show
    @creditor_order = CreditorOrder.find(params[:id])
  end

  def edit
    @creditor_order = CreditorOrder.find(params[:id])
  end

  def update

    fills = params[:fills]

    if fills.nil? || !fills.any?
      redirect_to creditor_orders_path
      return
    end

    fills.each do |fill|

      posting_id = fill[:posting_id].to_i
      quantity = fill[:quantity].to_i

      if quantity < 0
        next
      end

      posting = Posting.find_by(id: posting_id)

      if posting.nil?
        next
      end      

      fill_report = posting.fill(quantity)

    end

    redirect_to creditor_orders_path

  end

  def new
  end

  def create
  end

  def destroy
  end

  private

    def split_on_closed_postings(creditor_orders)
      
      if creditor_orders.nil?
        return
      end

      closed_creditor_orders = []
      unclosed_creditor_orders = []

      creditor_orders.each do |creditor_order|
        if creditor_order.all_postings_closed?
          closed_creditor_orders << creditor_order
        else
          unclosed_creditor_orders << creditor_order
        end
      end

      return {closed_creditor_orders: closed_creditor_orders, unclosed_creditor_orders: unclosed_creditor_orders}

    end

end