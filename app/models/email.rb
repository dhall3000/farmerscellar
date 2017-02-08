class Email < ApplicationRecord
  has_many :posting_emails
  has_many :postings, through: :posting_emails

  has_many :email_recipients
  has_many :recipients, through: :email_recipients, source: :user

  validates :subject, :body, presence: true
  validates_presence_of :postings

  def get_recipients(tote_item_states = nil)
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6}
    
    if recipients.count > 0
      return recipients
    end

    if tote_item_states.nil?
      tote_item_states = [
        ToteItem.states[:AUTHORIZED],
        ToteItem.states[:COMMITTED],
        ToteItem.states[:FILLED],
        ToteItem.states[:NOTFILLED]
      ]
    end

    if ToteItem.valid_state_values?(tote_item_states)
      
      to_users = User.joins(tote_items: :posting).where(tote_items: {state: tote_item_states}).where(postings: {id: postings}).distinct    
      to_users.each do |user|
        recipients << user
      end

      save
    
    end

    return recipients

  end

end