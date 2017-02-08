class Email < ApplicationRecord
  has_many :posting_emails
  has_many :postings, through: :posting_emails

  validates :subject, :body, presence: true
  validates_presence_of :postings

  def get_to_list
    return User.joins(tote_items: :posting).where(postings: {id: postings}).distinct    
  end

end