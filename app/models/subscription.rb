class Subscription < ApplicationRecord
  include ToteItemsHelper
  include ActionView::Helpers::NumberHelper

  belongs_to :user
  belongs_to :posting_recurrence
  has_many :subscription_skip_dates
  has_many :tote_items

  has_many :subscription_rtauthorizations
  has_many :rtauthorizations, through: :subscription_rtauthorizations

  validates :frequency, :quantity, presence: true
  validates :frequency, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates_presence_of :posting_recurrence, :user

  def turn_off
    update(on: false)
  end

  def pause(paused_value)
    update(paused: paused_value)
  end  

  def authorized?
    return rtauthorizations && rtauthorizations.order("rtauthorizations.id").last && rtauthorizations.order("rtauthorizations.id").last.authorized?
  end

  def description
    #this should return a string like: "3 dozens of Helen the Hen eggs every other week for a subtotal of $18.75 each delivery"
    posting = posting_recurrence.postings.order("postings.id").last
    friendly_frequency = posting_recurrence.subscription_description(frequency).downcase
    subtotal = number_to_currency(get_gross_cost(quantity, posting.price))
    text = "#{quantity.to_s} #{posting.unit.name.pluralize(quantity)} of #{posting.user.farm_name} #{posting.product.name} delivered #{friendly_frequency} for a subtotal of #{subtotal} each delivery"
    return text
  end

  def generate_next_tote_item
       
    if !generate_tote_item_for_current_posting?
      return nil
    end
  		  		
		tote_item = ToteItem.new(quantity: quantity, price: posting_recurrence.current_posting.price, posting_id: posting_recurrence.current_posting.id, user_id: user.id, subscription_id: id)

    #if there is no authorization for this subscription or the authorization is not active, add the
    #tote item in the ADDED state. otherwise, if everything's good to go and we're all authorized, add in state AUTHORIZED
    if authorized?
      tote_item.transition(:subscription_authorized)
    end

    last_auth = rtauthorizations.order("rtauthorizations.id").last

		if !rtauthorizations.nil? && !last_auth.nil?

  		#TODO: i don't think we really NEED need this. but doing it anyway. why is it that toteitems have_many rtauths and a subscription also has an auth? isn't one or the other
  		#sufficient. indeed, wouldn't it be cleaner to only have the subscription hold the reference to the rtauth parent? no, because toteitems can be atttached to an rtauth
  		#by means other than through subscriptions. as in, a person with a billing agreement can add a subscription to the auth but they can also add a single one-time-buy tote item      
  		last_auth.tote_items << tote_item
      last_auth.save

		end
		
		tote_item.save

		return tote_item  	

  end

  def is_future_delivery_date?(date)

    delivery_dates = get_delivery_dates(date - 1.day, date + 1.day)

    if delivery_dates.nil?
      return false
    end

    if !delivery_dates.any?
      return false
    end

    delivery_date = delivery_dates[0]

    return delivery_date == date

  end

  #this should return all dates regardless of skip dates
  #exclude start_date
  #include end_date
  def get_delivery_dates(start_date, end_date)

    puts "get_delivery_dates start: start_date=#{start_date.to_s}, end_date=#{end_date.to_s}"

    delivery_dates = []

    if end_date < start_date
      return delivery_dates
    end

    delivery_date = posting_recurrence.current_posting.delivery_date
    puts "get_delivery_dates: delivery_date=#{delivery_date.to_s}, end_date=#{end_date.to_s}"

    #quit when computed date is beyond end_date
    while delivery_date <= end_date

      #for each computed date include it if it falls within the parameterized date range
      if delivery_date > start_date
        delivery_dates << delivery_date
      end

      #compute next scheduled delivery date
      delivery_date = get_next_delivery_date(delivery_date)

    end

    return delivery_dates

  end

  private

    def get_next_delivery_date(prev_delivery_date)

      if posting_recurrence.frequency < 5 #weekly-based subscriptions
        next_delivery_date = posting_recurrence.get_delivery_dates_for(prev_delivery_date, prev_delivery_date + (frequency * posting_recurrence.frequency * 7).days)[frequency - 1]
      elsif posting_recurrence.frequency == 5 #monthly-based subscriptions
        next_delivery_date = posting_recurrence.get_delivery_dates_for(prev_delivery_date, prev_delivery_date + (2 * frequency).months)[frequency - 1]      
      end

      return next_delivery_date

    end

    def generate_tote_item_for_current_posting?

      #is subscription or posting recurrence off?
      if !on || !posting_recurrence.on
        return false
      end

      #subscription paused?
      if paused
        return false
      end

      delivery_date = posting_recurrence.current_posting.delivery_date
      delivery_dates = get_delivery_dates(delivery_date - 1.day, delivery_date + 1.day)

      #is this a normally deliverable date 
      if !delivery_dates.any?
        return false
      end

      delivery_date = delivery_dates[0]

      #do we already have a tote item for this delivery date?
      if tote_items && tote_items.any?
        last_live_tote_item = tote_items.where.not(state: ToteItem.states[:REMOVED]).joins(:posting).order("postings.delivery_date").last
        if last_live_tote_item && last_live_tote_item.posting.delivery_date == delivery_date
          return false
        end
      end

      #did user specify to skip this delivery?
      if subscription_skip_dates.find_by(skip_date: delivery_date)
        return false
      end

      return true

    end

end