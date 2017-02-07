class PostingEmail < ApplicationRecord
  belongs_to :posting
  belongs_to :email
end