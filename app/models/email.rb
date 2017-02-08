class Email < ApplicationRecord
  has_many :posting_emails
  has_many :postings, through: :posting_emails

  validates :subject, :body, presence: true
  validates_presence_of :postings

  def get_to_list
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLED: 4, NOTFILLED: 5, REMOVED: 6}
    #NOTE: as of now, ADDED and REMOVED are the only states that don't get an email. the reason for the ADDED
    #is because i'm thinking if we have some snafu folks need to be aware of, for now what we'll do is send
    #out an email, then put a .important_notes on the posting so that anybody adding will see the spinning
    #blue info glyph. on the other hand, now that i'm thinking of it, the ADDED's might not see it because i
    #don't think the tote displays the important_notes icon. anyway....
    #TODO: the plan now is that tomorrow gets implemented a feature where checkboxes are added for the states so
    #that user can state specifically who to contact
    return User.joins(tote_items: :posting).where(tote_items: {state: [
      ToteItem.states[:AUTHORIZED],
      ToteItem.states[:COMMITTED],
      ToteItem.states[:FILLED],
      ToteItem.states[:NOTFILLED]
      ]}).where(postings: {id: postings}).distinct    
  end

end