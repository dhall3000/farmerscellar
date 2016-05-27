class SubscriptionsController < ApplicationController
  before_action :logged_in_user

  def index
    @subscriptions = Subscription.where(user_id: current_user.id, on: true)
    get_view_data_for_subscriptions(@subscriptions)
  end

  def skip_dates

    #the idea here is that when someone clicks the 'Update' button we're going to unconditionally blast all the 
    #previously saved skip dates and then write these new ones. Yes, not as db efficient but more davidhall coder faster
    end_date = constrain_end_date(Time.zone.parse(params[:end_date]))
    old_skip_dates = get_skip_dates_through(params[:subscription_ids], end_date)

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
    redirect_to subscriptions_path(end_date: end_date)

  end

  def show

    get_show_or_edit_data

    @show_skip_dates = false

    @skip_dates.each do |skip_date|
      if skip_date[:skip]
        @show_skip_dates = true
      end
    end                

  end

  def edit
    get_show_or_edit_data
  end

  def update

    id = params[:id].to_i
    @subscription = Subscription.find_by(id: id)

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
      #blast all skip dates ahead of the present moment
      SubscriptionSkipDate.where("subscription_id = ? and skip_date > ?", id, Time.zone.now).delete_all
    else
      redirect_to subscriptions_path
      return
    end

    if @subscription.pause(pause_value)
      flash[:success] = "Subscription updated"
    else
      flash[:danger] = "Subscription not updated"
    end

    redirect_to subscription_path(@subscription)
    
  end

  def destroy
  end

  private

    def get_show_or_edit_data

      @subscriptions = Subscription.where(id: params[:id])
      @subscription = @subscriptions.last

      if @subscription.nil? || !@subscription.on
        redirect_to subscriptions_path
        return
      end

      get_view_data_for_subscriptions(@subscriptions)

    end

    def get_view_data_for_subscriptions(subscriptions)

      @end_date = Time.zone.now.midnight + 3.weeks

      if params[:end_date]
        @end_date = constrain_end_date(Time.zone.parse(params[:end_date]))
      end

      farthest_existing_skip_date = SubscriptionSkipDate.joins(subscription: :user).where("subscriptions.on" => true).order("subscription_skip_dates.skip_date").last
      @skip_dates = get_skip_dates_through(subscriptions.select(:id), @end_date)

      while @skip_dates.count == 0 && subscriptions.count > 0
        get_more_skip_dates
      end

      while farthest_existing_skip_date && farthest_existing_skip_date.skip_date > @skip_dates.last[:date]
        get_more_skip_dates
      end

    end

    def get_more_skip_dates
      @end_date += 4.weeks
      @skip_dates = get_skip_dates_through(@subscriptions.select(:id), @end_date)
    end

    def constrain_end_date(end_date)

      if end_date < Time.zone.now
        return Time.zone.tomorrow.midnight
      end

      max = Time.zone.now.midnight + 6.months

      if end_date > max
        end_date = max
      end

      return end_date

    end

    def get_skip_dates_through(subscription_ids, end_date)
      subscriptions = Subscription.where(id: subscription_ids)
      skip_dates = []

      subscriptions.each do |subscription|

        posting_recurrence = subscription.posting_recurrence
        #for each subscription get the next 10 delivery dates (exclude the delivery date of the current posting)
        delivery_dates = posting_recurrence.get_delivery_dates_for(posting_recurrence.current_posting.delivery_date, end_date)
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