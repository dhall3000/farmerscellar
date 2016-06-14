class User < ActiveRecord::Base
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest
  validates :name, length: { maximum: 50 }
  validates :zip, numericality: { only_integer: true, greater_than: 9999, less_than: 100000, message: " code invalid. Please enter a valid 5-digit zip code."}
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :farm_name, presence: true, if: :is_producer?
  validates :account_type, presence: true
  validates :account_type, numericality: {only_integer: true, greater_than: -1, less_than: 5, message: "account_type is invalid"}

  has_secure_password
  validates :password, length: { minimum: 6 }, allow_blank: true
  has_many :postings
  has_many :rtbas
  has_many :subscriptions
  has_many :pickups

  has_many :tote_items
  #has_many :postings, through: :tote_items

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

  #these are for if the account_type is either PRODUCER or DISTRIBUTOR
  #a distributor must a BusinessInterface
  #a producer must have either a DISTRIBUTOR or a BusinessInterface
  has_one :business_interface
  #if this object is type PRODUCER than it might have a distributor
  belongs_to :distributor, class_name: "User", foreign_key: "distributor_id"
  #if this object is type DISTRIBUTOR it might have many PRODUCERs
  has_many :producers, class_name: "User", foreign_key: "distributor_id"

  #PRODUCERs can have DISTRIBUTORs that have DISTRIBUTORs that have DISTRIBUTORs...
  #this method is recursive. it will start at the current level and traverse up the DISTRIBUTOR parenthood,
  #returning the first BusinessInterface it sees. So...if you start a relationship by dealing directly with
  #a PRODUCER and so have a BI associated, then later you fetch product for them through a DISTRIBUTOR, you 
  #have to not only set up the new DISTRIBUTOR association but you also have to nuke the PRODUCER's BI object
  #more likely though is that you'll 1st deal with a DISTRIBUTOR and then later deal directly with PRODUCER.
  #in that case you don't necessarily have to nuke the DISTRIBUTOR's BI for things to work correctly. Of course
  #for cleanliness' sake you should nuke the DISTRIBUTOR association altogether.
  def get_business_interface

    creditor = get_creditor

    if creditor.nil?
      return nil
    end

    return creditor.business_interface

  end

  def get_creditor

    if !account_type_is?(:PRODUCER) && !account_type_is?(:DISTRIBUTOR)
      return nil
    end

    if distributor.nil?
      return self
    else
      return distributor
    end

  end

  def tote_items_to_pickup
    #this should return a set of toteitems that have been delivered but not picked up yet

    #TODO: for now for 'delivered' we're going to use toteitem states FILLED or PURCHASED
    #this will eventually change though once we overhaul the toteitem statemachine

    #A) 7 days ago
    last_pickup = 7.days.ago
    if pickups.any?
      #or...
      #B) the last pickup
      last_pickup = pickups.order("pickups.id").last.created_at
    end

    #whichever is more recent
    cutoff = [last_pickup, 7.days.ago].max

    return tote_items.joins(:posting).where("postings.delivery_date > ? and postings.delivery_date < ?", cutoff, Time.zone.now).where(state: ToteItem.states[:FILLED])

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

  def is_producer?
    return account_type == 1
  end

  def self.types
    {CUSTOMER: 0, PRODUCER: 1, ADMIN: 2, DROPSITE: 3, DISTRIBUTOR: 4}
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
  
  private

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