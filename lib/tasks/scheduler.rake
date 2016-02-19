desc "This task is called by the Heroku scheduler add-on"

task :commit_totes => :environment do

  puts "rake task commit_totes start..."

  tote_items = ToteItem.where(status: ToteItem.states[:AUTHORIZED])

  if tote_items.count == 0
    puts "no authorized totes. quitting."

    #NOTE: this 'next' looks wrong. it's not. if you put a 'return' there it will crash.
    #don't know, don't care way, but in rake tasks you have to use a next, something like
    #because it's a block, not a method and blocks don't recognize/allow returns. whatever.
    next
  end

  transitioned_tote_ids = []
  transitioned_posting_ids = []

  tote_items.each do |tote_item|

    if tote_item.posting.commitment_zone_start.nil?
      next
    end

    if Time.zone.now >= tote_item.posting.commitment_zone_start
      tote_item.update(status: ToteItem.states[:COMMITTED])
      transitioned_tote_ids << tote_item.id
      transitioned_posting_ids << tote_item.posting.id
    end

  end

  if transitioned_posting_ids.nil? || !transitioned_posting_ids.any?
    puts "no postings transitioned. quitting."

    #NOTE: this 'next' looks wrong. it's not. if you put a 'return' there it will crash.
    #don't know, don't care way, but in rake tasks you have to use a next, something like
    #because it's a block, not a method and blocks don't recognize/allow returns. whatever.
    next
  end

  if !transitioned_tote_ids.nil? && transitioned_tote_ids.any?
    #send job summary report to admin
    subject = "commit_totes job summary report"
    body = get_commit_totes_email_body(transitioned_tote_ids)
    AdminNotificationMailer.general_message(subject, body).deliver_now
  end
  
  postings = Posting.find(transitioned_posting_ids.uniq)
  producers = {}

  postings.each do |posting|

    email = posting.user.email

    if !producers.has_key?(email)
      producers[email] = []
    end

    producers[email] << posting
    
  end

  producers.each do |email, postings|
    ProducerNotificationsMailer.current_orders(email, postings).deliver_now    
  end  

  puts "rake task commit_totes done."

end

def get_commit_totes_email_body(transitioned_tote_ids)

  body = ""

  if transitioned_tote_ids.nil?
    body = "empty body"
  else
    body = "number of tote_items transitioned from AUTHORIZED -> COMMITTED: #{transitioned_tote_ids.count}. tote_item ids transitioned: #{transitioned_tote_ids.to_s}."
  end

  return body
  
end

task :mailer_test => :environment do

  transitioned_tote_ids = [1,7,3,4]

  subject = "commit_totes job summary report"
  body = get_commit_totes_email_body(transitioned_tote_ids)

  AdminNotificationMailer.general_message(subject, body).deliver_now
  
end