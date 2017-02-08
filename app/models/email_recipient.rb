class EmailRecipient < ApplicationRecord
  belongs_to :email
  belongs_to :user
end
