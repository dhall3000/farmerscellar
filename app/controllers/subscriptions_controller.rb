class SubscriptionsController < ApplicationController
  before_action :logged_in_user

  def index

    @subscriptions = Subscription.where(user_id: current_user.id, on: true)
    @num_dates = 1

    if params[:num_dates]
      @num_dates = constrain_num_dates(params[:num_dates].to_i)
    end

    farthest_existing_skip_date = SubscriptionSkipDate.joins(subscription: :user).where("subscriptions.on" => true).order("subscription_skip_dates.skip_date").last
    @skip_dates = get_skip_dates_for(@subscriptions.select(:id), @num_dates)

    while farthest_existing_skip_date && farthest_existing_skip_date.skip_date > @skip_dates.last[:date]
      @num_dates += 3
      @skip_dates = get_skip_dates_for(@subscriptions.select(:id), @num_dates)
    end    

  end

  def skip_dates

    #the idea here is that when someone clicks the 'Update' button we're going to unconditionally blast all the 
    #previously saved skip dates and then write these new ones. Yes, not as db efficient but more davidhall coder faster
    num_dates = constrain_num_dates(params[:num_dates].to_i)
    old_skip_dates = get_skip_dates_for(params[:subscription_ids], num_dates)
    old_skip_dates.each do |old_skip_date|
      SubscriptionSkipDate.where(subscription_id: old_skip_date[:subscription].id, skip_date: old_skip_date[:date]).delete_all
    end

    if params[:skip_dates]
      params[:skip_dates].each do |subscription_id, dates|

        dates.each do |date|
          SubscriptionSkipDate.create(subscription_id: subscription_id, skip_date: date)
        end      
        
      end
    end

    flash[:success] = "Delivery skip dates updated"
    redirect_to subscriptions_path(num_dates: num_dates)

  end

  def show

    @subscription = Subscription.find_by(id: params[:id])

    if @subscription.nil? || !@subscription.on
      redirect_to subscriptions_path
      return
    end

  end

  def edit

    @subscription = Subscription.find_by(id: params[:id])

    if @subscription.nil? || !@subscription.on
      redirect_to subscriptions_path
      return
    end

  end

  def update

    @subscription = Subscription.find_by(id: params[:id])

    if @subscription.nil? || !@subscription.on
      redirect_to subscriptions_path
      return
    end

    on = params[:subscription][:on].to_i
    if on == 0
      
      if @subscription.turn_off
        flash[:success] = "Subscription canceled"
      else
        flash[:danger] = "Subscription not canceled"
      end

      redirect_to subscriptions_path
      return

    end

    paused = params[:subscription][:paused].to_i
    flash_message = "Subscription is now "

    if paused == 0
      pause_value = false            
    elsif paused == 1
      pause_value = true      
    else
      redirect_to subscriptions_path
      return
    end

    if @subscription.pause(pause_value)
      flash[:success] = "Subscription updated"
    else
      flash[:danger] = "Subscription not updated"
    end

    redirect_to edit_subscription_path(@subscription)

  end

  def destroy
  end

  private

    def constrain_num_dates(num_dates)

      if num_dates < 1
        num_dates = 1
      end

      if num_dates > 20
        num_dates = 20
      end

      return num_dates

    end


    def get_skip_dates_for(subscription_ids, num_future_delivery_dates_per_subscription)

      subscriptions = Subscription.where(id: subscription_ids)
      skip_dates = []

      subscriptions.each do |subscription|
        #for each subscription get the next 10 delivery dates (exclude the delivery date of the current posting)
        delivery_dates = subscription.posting_recurrence.get_next_delivery_dates(num_future_delivery_dates_per_subscription, subscription.posting_recurrence.current_posting.delivery_date)
        #see if any of the delivery dates exist in the skip dates table
        delivery_dates.each do |delivery_date|

          if SubscriptionSkipDate.find_by(subscription_id: subscription.id, skip_date: delivery_date)
            skip = true
          else
            skip = false
          end        

          skip_date = {subscription: subscription, date: delivery_date, skip: skip}
          skip_dates << skip_date

        end      
        
      end

      skip_dates.sort_by! { |hash| hash[:date]}

      return skip_dates
   
    end

end