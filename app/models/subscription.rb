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

    #try to add the next tote item in the series. it can be called any number of times successively and will only
    #add a single tote item at most because it does its own logic to tell when is the right time to add.
    current_posting = posting_recurrence.current_posting
    expected_next_delivery_date = get_expected_next_delivery_date

  	#if there are no tote items in this series yet or if the last tote item delivery date is behind the
  	#current posting, create a new tote item
    if current_posting.delivery_date == expected_next_delivery_date
  		  		
  		tote_item = ToteItem.new(quantity: quantity, price: current_posting.price, posting_id: current_posting.id, user_id: user.id, subscription_id: id)

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

  	return nil

  end

  #this should return all dates regardless of skip dates
  #exclude start_date
  #include end_date
  def get_delivery_dates(start_date, end_date)

    delivery_dates = []

    if end_date < start_date
      return delivery_dates
    end

    if !tote_items || !tote_items.any?
      return delivery_dates
    end

    #start at tote_items.first and compute forward
    delivery_date = tote_items.first.posting.delivery_date
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

  #NUKE
  def get_expected_next_delivery_date

    expected_next_delivery_date = posting_recurrence.current_posting.delivery_date

    if !tote_items || !tote_items.any?
      return expected_next_delivery_date
    end

    if posting_recurrence.frequency < 5 #weekly-based subscriptions
      weeks_between_postings = posting_recurrence.frequency * self.frequency
      expected_next_delivery_date = tote_items.last.posting.delivery_date + weeks_between_postings.weeks
    elsif posting_recurrence.frequency == 5 #monthly-based subscriptions
      case self.frequency
        when 1 #monthly
          #TODO: finish
        when 2 #every other month
          #TODO: finish
        end
    elsif posting_recurrence.frequency == 6 #this is Marty/Helen the Hen's "3 weeks on, 1 week off" schedule
      case self.frequency
        when 1 #every delivery
          #nothing to do, just return default value from above
        when 2 #every other week
          #nothing to do, just return default value from above
        when 3 #every 4 weeks
          expected_next_delivery_date = tote_items.last.posting.delivery_date + 4.weeks
        end
    end

    return expected_next_delivery_date

  end

end
