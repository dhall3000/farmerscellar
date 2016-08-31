class AccountState < ApplicationRecord
  has_many :user_account_states
  has_many :users, through: :user_account_states

  #HOW TO: this class autopopulates itself in the database. If you ever want to establish a new account state, all you have to do is
  #make an appropriate entry in the self.states and self.descriptions hashes below. This is so because the
  #self.auto_populate_database method checks for the existence of each state and creates a new record for it if none exists.
  #self.auto_populate_database gets called in all environments when the server starts up.

  def self.states
    {OK: 0, HOLD: 1}
  end

  def self.descriptions
  	{
  	  OK: "account is in good standing with full permissions",
      HOLD: "user can log in but cannot browse, order or post"
  	}
  end

  #make a call like this: AccountState.get_record_for(:HOLD)
  def self.get_record_for(state_key)
    state_value = states[state_key]
    record = find_by(state: state_value)
    return record
  end

  def self.auto_populate_database

    if !ActiveRecord::Base.connection.data_source_exists? 'account_states'
      return
    end

    states.each do |key, value|
      record = find_by(state: value)
      if record.nil?
        AccountState.create(state: value, description: descriptions[key])
      end
    end
  end

end
