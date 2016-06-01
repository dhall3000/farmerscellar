class SubscriptionsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user, only: [:show, :edit, :update]

  def new

    if !new_conditions_met?
      return
    end

    @subscription_create_options = @tote_item.posting.posting_recurrence.subscription_create_options
    
  end

  def create

    if !new_conditions_met?
      return
    end

    if params[:frequency].nil?
      redirect_to postings_path
      return
    end

    frequency = params[:frequency].to_i
    frequency_is_legit = frequency_is_legit?(@tote_item, frequency)

    if !frequency_is_legit
      redirect_to postings_path
      return
    end

    if frequency == 0
      flash[:success] = "Tote item created"
      redirect_to postings_path
      return
    end

    @subscription = Subscription.new(frequency: frequency, on: true, user_id: current_user.id, posting_recurrence_id: @posting_recurrence.id, quantity: @tote_item.quantity, paused: false)
    if @subscription.save
      @subscription.tote_items << @tote_item
      @subscription.save
      flash[:success] = "Subscription created"
      redirect_to postings_path
      return
    else
      AdminNotificationMailer.general_message("Subscription failed to create", @subscription.to_yaml).deliver_now
      flash[:danger] = "Subscription not created"
      redirect_to postings_path
      return
    end

  end

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

      #before nuking this skip date, pull up the subscription from the id and verify it really belongs to the current user
      subscription_id = old_skip_date[:subscription].id
      subscription = Subscription.find_by(id: subscription_id)

      if subscription && subscription.user.id == current_user.id
        #ok, subscription exists and belongs to current user...nuke the skip date
        SubscriptionSkipDate.where(subscription_id: subscription_id, skip_date: old_skip_date[:date]).delete_all
      end

    end

    if params[:skip_dates]
      params[:skip_dates].each do |subscription_id, dates|

        #before programming in the skip dates, verify the subscription really belongs to current_user
        subscription = Subscription.find_by(id: subscription_id)

        if subscription && subscription.user.id == current_user.id
          dates.each do |date|
            SubscriptionSkipDate.create(subscription_id: subscription_id, skip_date: date)
          end      
        end
        
      end
    end

    flash[:success] = "Delivery skip dates updated"
    redirect_to subscriptions_path(end_date: end_date)

  end

  def show

    get_show_or_edit_data

    if @skip_dates && @skip_dates.any?

      actual_skip_dates = []

      @skip_dates.each do |skip_date|
        if skip_date[:skip]
          actual_skip_dates << skip_date
        end
      end        

      @skip_dates = actual_skip_dates        

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

        SubscriptionSkipDate.where("subscription_id = ? and skip_date > ?", id, Time.zone.now).delete_all      
        unremovable_items = remove_items_from_tote_for_this_subscription
        if unremovable_items.any?
          flash[:info] = "Subscription canceled. Note that your tote still has some items scheduled for delivery."
        else
          flash[:success] = "Subscription canceled"
        end
        
      else
        flash[:danger] = "Subscription not canceled"
      end

      redirect_to subscriptions_path
      return

    end

    paused = params[:subscription][:paused].to_i
    if paused == 0
      pause_value = false            
    elsif paused == 1
      pause_value = true
      #blast all skip dates ahead of the present moment
      SubscriptionSkipDate.where("subscription_id = ? and skip_date > ?", id, Time.zone.now).delete_all      
      unremovable_items = remove_items_from_tote_for_this_subscription
    else
      redirect_to subscriptions_path
      return
    end

    if @subscription.pause(pause_value)

      if !@subscription.paused
        tote_item = @subscription.generate_next_tote_item
      end            

      if pause_value && unremovable_items.any?
        flash[:info] = "Subscription paused. Note that your tote still has some items scheduled for delivery."
      else
        flash[:success] = "Subscription updated"
      end
      
    else
      flash[:danger] = "Subscription not updated"
    end

    redirect_to subscription_path(@subscription)
    
  end

  private

    def new_conditions_met?

      #if tote_item_id is not in params, redirect to postings page
      if params[:tote_item_id].nil?
        redirect_to postings_path
        return false
      end

      @tote_item = ToteItem.find_by(id: params[:tote_item_id])

      #if tote_item_id does not belong to current user, redirect to postings page
      if !@tote_item || @tote_item.user.id != current_user.id
        redirect_to postings_path
        return false
      end

      #if tote item's posting is not subscribable, redirect to postings page
      if @tote_item.posting.posting_recurrence.nil? || !@tote_item.posting.posting_recurrence.subscribable?
        redirect_to postings_path
        return false
      end

      return true

    end

    def correct_user
      
      subscription = Subscription.find_by(id: params[:id])

      if !subscription || !current_user?(subscription.user)
        redirect_to subscriptions_path
      end      

    end

    def remove_items_from_tote_for_this_subscription

      items = @subscription.tote_items.joins(:posting).where("postings.delivery_date >= ?", Time.zone.now.midnight)
      unremovable_items = []

      items.each do |item|
        case item.state
        when ToteItem.states[:ADDED], ToteItem.states[:AUTHORIZED]
          item.transition(:customer_removed)
        when ToteItem.states[:COMMITTED]
          unremovable_items << item
        end
      end

      return unremovable_items

    end

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

      if !subscriptions || !subscriptions.any?
        @end_date = nil
        @skip_dates = nil
        return
      end

      @end_date = Time.zone.now.midnight + 3.weeks

      if params[:end_date]
        @end_date = constrain_end_date(Time.zone.parse(params[:end_date]))
      end

      farthest_existing_skip_date = SubscriptionSkipDate.joins(subscription: :user).where("subscriptions.on" => true, "subscriptions.user_id" => current_user.id).order("subscription_skip_dates.skip_date").last
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
        posting_recurrence_delivery_dates = posting_recurrence.get_delivery_dates_for(posting_recurrence.current_posting.delivery_date, end_date)
        #see if any of the delivery dates exist in the skip dates table
        posting_recurrence_delivery_dates.each do |posting_recurrence_delivery_date|

          if !subscription.is_future_delivery_date?(posting_recurrence_delivery_date)
            next
          end

          if SubscriptionSkipDate.find_by(subscription_id: subscription.id, skip_date: posting_recurrence_delivery_date)
            skip = true
          else
            skip = false
          end        

          skip_date = {subscription: subscription, date: posting_recurrence_delivery_date, skip: skip}
          skip_dates << skip_date

        end      
        
      end

      skip_dates.sort_by! { |hash| hash[:date]}

      return skip_dates

    end

    #find the posting recurrence associted with the given tote item and determine if the frequency parameter
    #is actually an option for that posting recurrence
    def frequency_is_legit?(tote_item, frequency)

      frequency_is_legit = false

      @posting_recurrence = tote_item.posting.posting_recurrence

      subscription_create_options = @posting_recurrence.subscription_create_options
      subscription_create_options.each do |subscription_create_option|
        if subscription_create_option[:subscription_frequency] == frequency
          frequency_is_legit = true
        end
      end

      return frequency_is_legit

    end

end