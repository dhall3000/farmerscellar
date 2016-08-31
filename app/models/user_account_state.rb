class UserAccountState < ApplicationRecord
  belongs_to :account_state
  belongs_to :user

  def self.ensure_state_exists(user)
  	state = UserAccountState.find_by(user_id: user.id)
  	if state.nil?
  	  add_new_state(user, :OK, "first login. everything ok.")
  	end
  end

  #call this method like this: UserAccountState.add_new_state(user, :HOLD, "person's oustanding account balance is too high.")
  def self.add_new_state(user, state, notes)
    account_state_record = AccountState.get_record_for(state)
    if !account_state_record.nil?
      UserAccountState.create(account_state_id: account_state_record.id, user_id: user.id, notes: notes)
    end
  end

end