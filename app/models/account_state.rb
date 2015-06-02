class AccountState < ActiveRecord::Base
  has_many :user_account_states
  has_many :users, through: :user_account_states

  def self.states
    {OK: 0, HOLD: 1}
  end

  def self.descriptions
  	{
  	  OK: "account is in good standing with full permissions"
  	}
  end
end
