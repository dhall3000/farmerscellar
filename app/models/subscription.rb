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

  	#try to add the next tote item in the series. it can be called any number of times successively and will only
  	#add a single tote item at most because it does its own logic to tell when is the right time to add.
  	
  	current_posting = posting_recurrence.current_posting
    next_delivery_date = posting_recurrence.next_delivery_date(frequency)

  	#if the next delivery date in the series for this subscription frequency is beyond (datewise) the currently
  	#posted posting in the posting_recurrence postings series, we don't generate a new tote_item here
  	if current_posting.delivery_date < next_delivery_date
  		return nil
  	end

  	#if there are no tote items in this series yet or if the last tote item delivery date is behind the
  	#current posting, create a new tote item
    if (current_posting.delivery_date == next_delivery_date) && (!tote_items.any? || (tote_items.last.posting.delivery_date < next_delivery_date))
  		  		
  		tote_item = ToteItem.new(quantity: quantity, price: current_posting.price, posting_id: current_posting.id, user_id: user.id, subscription_id: id)
      tote_item.set_initial_state

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

end
