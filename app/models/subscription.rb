class Subscription < ActiveRecord::Base
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
    return rtauthorizations && rtauthorizations.last && rtauthorizations.last.authorized?
  end

  def description
    #this should return a string like: "3 dozens of Helen the Hen eggs every other week for a subtotal of $18.75 each delivery"
    posting = posting_recurrence.postings.last
    friendly_frequency = posting_recurrence.subscription_description(frequency).downcase
    subtotal = number_to_currency(get_gross_cost(quantity, posting.price))
    text = "#{quantity.to_s} #{posting.unit_kind.name.pluralize(quantity)} of #{posting.user.farm_name} #{posting.product.name} delivered #{friendly_frequency} for a subtotal of #{subtotal} each delivery"
    return text
  end

  def generate_next_tote_item

    if !on || !posting_recurrence.on
      return nil
    end

    #as of this writing (2016-05-25) there's only one case where this could ever fail; marty's 3 on 1 off delivery schedule
    #when a customer is trying to add a every-other-week subscription on week #2 of his delivery cycle
    if !posting_recurrence.can_add_tote_item?(frequency)      
      return nil
    end
       
    if !generate_tote_item_for_current_posting?
      return nil
    end
  		  		
		tote_item = ToteItem.new(quantity: quantity, price: posting_recurrence.current_posting.price, posting_id: posting_recurrence.current_posting.id, user_id: user.id, subscription_id: id)

    #if there is no authorization for this subscription or the authorization is not active, add the
    #tote item in the ADDED state. otherwise, if everything's good to go and we're all authorized, add in state AUTHORIZED
    if authorized?
      tote_item.transition(:subscription_authorized)
    end

		if !rtauthorizations.nil? && !rtauthorizations.last.nil?

  		#TODO: i don't think we really NEED need this. but doing it anyway. why is it that toteitems have_many rtauths and a subscription also has an auth? isn't one or the other
  		#sufficient. indeed, wouldn't it be cleaner to only have the subscription hold the reference to the rtauth parent? no, because toteitems can be atttached to an rtauth
  		#by means other than through subscriptions. as in, a person with a billing agreement can add a subscription to the auth but they can also add a single one-time-buy tote item
  		rtauthorizations.last.tote_items << tote_item
      rtauthorizations.last.save

		end
		
		tote_item.save

		return tote_item  	

  end

  #this should return all dates regardless of skip dates
  #exclude start_date
  #include end_date
  def get_delivery_dates(start_date, end_date)

    delivery_dates = []

    if end_date < start_date
      return delivery_dates
    end

    if tote_items && tote_items.any?
      #start at tote_items.first and compute forward
      delivery_date = tote_items.first.posting.delivery_date
    else
      delivery_date = posting_recurrence.current_posting.delivery_date
    end

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

  def get_next_delivery_date(prev_delivery_date)

    if posting_recurrence.frequency < 5 #weekly-based subscriptions
      next_delivery_date = posting_recurrence.get_delivery_dates_for(prev_delivery_date, prev_delivery_date + (frequency * posting_recurrence.frequency).weeks)[frequency - 1]
    elsif posting_recurrence.frequency == 5 #monthly-based subscriptions
      next_delivery_date = posting_recurrence.get_delivery_dates_for(prev_delivery_date, prev_delivery_date + (2 * frequency).months)[frequency - 1]
    elsif posting_recurrence.frequency == 6 #this is Marty/Helen the Hen's "3 weeks on, 1 week off" schedule
      case self.frequency
        when 1 #every delivery
          next_delivery_date = posting_recurrence.get_delivery_dates_for(prev_delivery_date, prev_delivery_date + 3.weeks)[0]
        when 2 #every other week
          next_delivery_date = prev_delivery_date + 2.weeks
        when 3 #every 4 weeks
          next_delivery_date = prev_delivery_date + 4.weeks
        end
    end

    return next_delivery_date

  end

  def generate_tote_item_for_current_posting?

    delivery_date = posting_recurrence.current_posting.delivery_date
    delivery_dates = get_delivery_dates(delivery_date - 1.day, delivery_date + 1.day)

    #is this a normally deliverable date 
    if !delivery_dates.any?
      return false
    end

    delivery_date = delivery_dates[0]

    #do we already have a tote item for this delivery date?
    if tote_items && tote_items.any?
      if tote_items.joins(:posting).order("postings.delivery_date").last.posting.delivery_date == delivery_date
        return false
      end
    end

    #TODO: is subscription paused?
    #TODO: is subscription off?

    #did user specify to skip this delivery?
    if subscription_skip_dates.find_by(skip_date: delivery_date)
      return false
    end

    return true

  end

end