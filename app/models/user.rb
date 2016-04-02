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
  validates :account_type, numericality: {only_integer: true, greater_than: -1, less_than: 3, message: "account_type is invalid"}

  has_secure_password
  validates :password, length: { minimum: 6 }, allow_blank: true
  has_many :postings
  has_many :rtbas
  has_many :subscriptions

  has_many :tote_items
  #has_many :postings, through: :tote_items

  has_many :user_account_states
  has_many :account_states, through: :user_account_states

  has_many :user_purchase_receivables
  has_many :purchase_receivables, through: :user_purchase_receivables

  has_many :producer_product_commissions
  has_many :products, through: :producer_product_commissions

  has_many :user_dropsites
  has_many :dropsites, through: :user_dropsites

  has_one :access_code

  def is_producer?
    return account_type == 1
  end

  def self.types
    {CUSTOMER: 0, PRODUCER: 1, ADMIN: 2}
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