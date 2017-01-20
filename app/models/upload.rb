class Upload < ApplicationRecord
  has_many :posting_uploads
  has_many :postings, through: :posting_uploads

  mount_uploader :name, ImageUploader
end