class UserAccountState < ActiveRecord::Base
  belongs_to :account_state
  belongs_to :user
end
