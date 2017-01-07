class CreditorOrdersController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin

  def index
    @open_orders = CreditorOrder.where(state: CreditorOrder.state(:OPEN)).order(delivery_date: :asc)
    @closed_orders = CreditorOrder.joins(:postings).distinct.where(state: CreditorOrder.state(:CLOSED)).where("postings.delivery_date > ?", Time.zone.now.midnight - 8.weeks).order(delivery_date: :desc)
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

    redirect_to creditor_orders_path

  end

  def new
  end

  def create
  end

  def destroy
  end

end