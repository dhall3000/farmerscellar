class User < ApplicationRecord
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  validates :name, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :farm_name, presence: true, if: :producer?
  validates :account_type, presence: true
  validates :account_type, numericality: {only_integer: true, greater_than: -1, less_than: 5, message: "account_type is invalid"}

  has_secure_password
  validates :password, length: { minimum: 6 }, allow_blank: true
  has_many :postings
  has_many :rtbas
  has_many :subscriptions
  has_many :pickups
  has_many :partner_deliveries
  has_many :tote_items

  has_many :user_account_states
  has_many :account_states, through: :user_account_states

  has_many :user_purchase_receivables
  has_many :purchase_receivables, through: :user_purchase_receivables

  has_many :producer_product_unit_commissions
  has_many :products, through: :producer_product_unit_commissions

  has_many :user_dropsites
  has_many :dropsites, through: :user_dropsites

  has_one :access_code
  has_one :pickup_code
  has_one :setting

  #how do the producer/distributor stuff work: it used to be the distributors were 100% not producers and vice versa. but
  #that got changed. now a producer can be by itself or it can have a parent producer. this also is a bit of a hack.
  #it fits ok in a situation like Helen the Hen + Baron Farms or Oxbow and the fruit farm they distribute for. But it's hack'ish
  #for Select Gourmet Foods because they aren't a producer but now they'll be entered as a producer account. oh well, i guess
  #can't win 'em' all

  #these are for if the account_type is PRODUCER
  #a distributor must have a BusinessInterface
  #a producer must have either a distributor or a BusinessInterface
  has_one :business_interface
  #if this object is type PRODUCER than it might have a distributor
  belongs_to :distributor, class_name: "User", foreign_key: "distributor_id"
  #if this object is a distributor it might have many PRODUCERs
  has_many :producers, class_name: "User", foreign_key: "distributor_id"

  def inbound_order_report(order_cutoff)

    #postings_order_requirements_met, postings_order_requirements_unmet, order_value_producer_net
    postings_order_requirements_met = []
    postings_order_requirements_unmet = []
    order_value_producer_net = 0
    
    #loop through my postings and sum their order value
    postings.where(commitment_zone_start: order_cutoff).each do |posting|

      posting_outbound_order_value_producer_net = posting.outbound_order_value_producer_net

      order_value_producer_net = (order_value_producer_net + posting_outbound_order_value_producer_net).round(2)

      if posting_outbound_order_value_producer_net > 0
        postings_order_requirements_met << posting
      else
        postings_order_requirements_unmet << posting
      end
      
    end

    #loop through my producers (if any) and sum their order value
    producers.each do |producer|
      producer_outbound_order_report = producer.outbound_order_report(order_cutoff)
      postings_order_requirements_met.concat(producer_outbound_order_report[:postings_order_requirements_met])
      postings_order_requirements_unmet.concat(producer_outbound_order_report[:postings_order_requirements_unmet])
      order_value_producer_net = (order_value_producer_net + producer_outbound_order_report[:order_value_producer_net]).round(2)
    end

    return {postings_order_requirements_met: postings_order_requirements_met, postings_order_requirements_unmet: postings_order_requirements_unmet, order_value_producer_net: order_value_producer_net}

  end

  def outbound_order_report(order_cutoff)
    
    inbound = inbound_order_report(order_cutoff)

    if inbound[:order_value_producer_net] >= order_minimum_producer_net
      return inbound
    else

      #ok, nothing should be ordered so concat all the postings in the 'unmet' hash key      
      postings_order_requirements_unmet = inbound[:postings_order_requirements_unmet].concat(inbound[:postings_order_requirements_met])
      postings_order_requirements_met = []      
      order_value_producer_net = 0

      return {postings_order_requirements_met: postings_order_requirements_met, postings_order_requirements_unmet: postings_order_requirements_unmet, order_value_producer_net: order_value_producer_net}

    end

  end

  def inbound_order_value_producer_net(order_cutoff)
    return inbound_order_report(order_cutoff)[:order_value_producer_net]
  end

  def outbound_order_value_producer_net(order_cutoff)
    return outbound_order_report(order_cutoff)[:order_value_producer_net]
  end

  def settings

    if setting.nil?
      create_setting
    end

    return setting

  end

  def current_account_state

    if user_account_states.nil?
      return nil
    end

    if user_account_states.any?

      last_state = user_account_states.order(:created_at).last.account_state

      if last_state.nil?
        return nil
      else
        return last_state.state
      end

    end

    return nil
    
  end

  def account_currently_on_hold?

    if account_states == nil || !account_states.any?
      return false
    end

    return current_account_state == AccountState.states[:HOLD]

  end

  def filled_items_at_dropsite
    return tote_items.joins(:posting).where("postings.delivery_date > ? and tote_items.state = ?", cutoff, ToteItem.states[:FILLED]).order("postings.delivery_date")
  end

  def partner_deliveries_at_dropsite
    return partner_deliveries.where("created_at > ?", cutoff)
  end

  def producer?
    return account_type_is?(:PRODUCER)
  end

  def distributor?
    return producer? && producers.any?
  end
  
  #this method is recursive. it will start at the current level and traverse up the distributor parenthood,
  #returning the first BusinessInterface it sees. So...if you start a relationship by dealing directly with
  #a PRODUCER and so have a BI associated, then later you fetch product for them through a distributor, you 
  #have to not only set up the new distributor association but you also have to nuke the PRODUCER's BI object
  #more likely though is that you'll 1st deal with a distributor and then later deal directly with PRODUCER.
  #in that case you don't necessarily have to nuke the distributor's BI for things to work correctly. Of course
  #for cleanliness' sake you should nuke the distributor association altogether. well maybe not because you probably
  #won't nuke the distributor relationship all at once. you'll probably just convert one PRODUCER at a time to
  #direct sourcing and then eventually do away with the distributor entirely.
  def get_business_interface

    creditor = get_creditor

    if creditor.nil?
      return nil
    end

    return creditor.business_interface

  end

  def get_creditor

    if !account_type_is?(:PRODUCER)
      return nil
    end

    if distributor.nil?
      return self
    else
      return distributor
    end

  end

  def order_minimum_met?(producer_net_total)

    if self.order_minimum_producer_net.nil?            
      return true
    end

    if producer_net_total >= self.order_minimum_producer_net
      return true
    end

    return false

  end  

  def tote_items_to_pickup

    #this should return a set of toteitems that have been delivered but not picked up yet

    #TODO: for now for 'delivered' we're going to use toteitem states FILLED or PURCHASED
    #this will eventually change though once we overhaul the toteitem statemachine

    if dropsite.nil?
      return nil
    end

    #whichever is more recent
    if previous_pickup
      previous_pickup_time = previous_pickup.created_at
    else
      previous_pickup_time = dropsite.last_food_clearout
    end

    #there is a private method called 'cutoff' and i don't want to get mixed up with that so just stick an 'x' on it and call it good    
    xcutoff = [previous_pickup_time, dropsite.last_food_clearout].max

    return tote_items.joins(:posting).where("postings.delivery_date > ? and postings.delivery_date < ?", xcutoff, Time.zone.now).where(state: [ToteItem.states[:FILLED], ToteItem.states[:NOTFILLED]])

  end

  def tote_items_delivered_since_last_food_clearout    
    return tote_items.joins(:posting).where("postings.delivery_date > ? and tote_items.state = ?", dropsite.last_food_clearout, ToteItem.states[:FILLED])
  end

  def partner_deliveries_since_last_food_clearout
    return partner_deliveries.where("created_at > ?", dropsite.last_food_clearout)
  end

  def delivery_since_last_dropsite_clearout?

    if dropsite.nil?
      return false
    end

    return tote_items_delivered_since_last_food_clearout.any? || partner_deliveries_since_last_food_clearout.any?

  end

  def previous_pickup
    return pickups.where("created_at < ?", Time.zone.now - 60.minutes).order("pickups.id").last
  end

  def set_dropsite(dropsite)

    if dropsite.nil?
      return
    end

    if dropsite.class.to_s != "Dropsite"
      return
    end

    if !dropsite.valid?
      return
    end

    dropsites << dropsite

    set_pickup_code_if_nil(dropsite)

  end

  def set_pickup_code_if_nil(dropsite)
    
    if pickup_code.nil?
      create_pickup_code(user: self)
    end

    pickup_code.set_code(dropsite)
    save

  end

  def dropsite
    
    if dropsites.nil? || !dropsites.any?
      return nil
    end

    dropsite = Dropsite.find(dropsites.joins(:user_dropsites).order('user_dropsites.created_at').last.id)

    return dropsite

  end

  def get_active_rtba

    if rtbas.nil? || !rtbas.any?            
      return nil
    end

    rtba = rtbas.order("rtbas.id").last

    if rtba.active == false
      return nil
    end
    
    return rtba

  end

  def self.types
    {CUSTOMER: 0, PRODUCER: 1, ADMIN: 2, DROPSITE: 3}
  end

  def account_type_is?(type_key)

    if !User.types.has_key?(type_key)
      return false
    end

    return self.account_type == User.types[type_key]
    
  end

  def self.farm_name_from_posting_id(id)
    posting = Posting.find(id)
    if posting != nil
      user = User.find(posting.user_id)
      if user != nil
        user.farm_name
      end
    end
  end

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token
  	SecureRandom.urlsafe_base64
  end

  def remember
  	self.remember_token = User.new_token
  	update_attribute(:remember_digest, User.digest(remember_token))
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  def authenticated?(attribute, token)
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Activates an account.
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    create_activation_digest
    save
    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Sends authorization receipt email.
  def send_authorization_receipt(authorization)
    UserMailer.authorization_receipt(self, authorization).deliver_now
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  
  def send_pickup_deadline_reminder_email

    if filled_items_at_dropsite.any? || partner_deliveries_at_dropsite.any?
      puts "user #{id.to_s}, #{email} has products remaining. sending them a pickup deadline reminder."
      UserMailer.pickup_deadline_reminder(self, filled_items_at_dropsite, partner_deliveries_at_dropsite).deliver_now
    else
      puts "user #{id.to_s}, #{email} has no products remaining. not sending them a pickup deadline reminder."
    end    
    
  end
  
  private

    def cutoff
      
      if pickups.any?
        #we want what's most recent, user's last pickup or the last food clearout
        return [pickups.last.created_at, dropsite.last_food_clearout].max
      else
        #user's never picked up before so just get the latest food clearout
        return dropsite.last_food_clearout
      end

    end

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end  
    
end