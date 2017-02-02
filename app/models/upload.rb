class Upload < ApplicationRecord
  has_many :posting_uploads
  has_many :postings, through: :posting_uploads

  has_many :food_category_uploads
  has_many :food_categories, through: :food_category_uploads

  mount_uploader :file_name, ImageUploader

  validates :title, uniqueness: true, allow_nil: true
end