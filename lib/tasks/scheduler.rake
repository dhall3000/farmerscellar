desc "This task is called by the Heroku scheduler add-on"

task :commit_totes => :environment do

  puts "comitting totes..."

  tote_items = ToteItem.where(status: ToteItem.states[:AUTHORIZED])

  transitioned_tote_ids = []

  tote_items.each do |tote_item|

  	#the '-40' is not obvious. this is being written here in Seattle, Pacific Standard Time. From UTC we're either
  	#-0700 or -0800 depending on daylight savings (DST). i'm in a hurry trying to ship MVP + 1 so i don't want
  	#to fiddle with DST at all. So I'm just going to say that the transition from AUTHORIZED -> COMMITTED
  	#occurs at 8AM UTC regardless. So, in reality, here in PST the transition will happen at midnight or
  	#1AM, depending on DST. ok, so the .posting.delivery_date value is midnight UTC on the date of delivery.
  	#but that date/time value is equivalent to 4PM PST. 4PM PST is not the transition time we want. We want
  	#midnight PST transition time. So we have to +8 hours for that. But then we want this transition time to be
  	#2 days prior to delivery date so that's -48 hours. So, if you sum -48 and +8 you end up with -40. This makes
  	#the AUTH -> COMMIT transition time happen at midnight (or 1AM, depending on local DST) PST. ugh.
  	commit_transition_time = tote_item.posting.delivery_date - 40 * 60 * 60

  	#if (DateTime.now + 1).getutc >= commit_transition_time
    if DateTime.now.getutc >= commit_transition_time
	    #do transition...
	    tote_item.update(status: ToteItem.states[:COMMITTED])
      transitioned_tote_ids << tote_item.id
	  end

  end

  #send job summary report to admin
  subject = "commit_totes job summary report"
  body = get_commit_totes_email_body(transitioned_tote_ids)
  AdminNotificationMailer.general_message(subject, body).deliver_now

  producers = {}

  #this, of course, snags all postings with future delivery dates. that isn't quite what we want though.
  #we want the subset of that whose delivery date is within 1-2 days from now. so here snag all,
  #then we'll strip down to get that subset.
  postings = Posting.where("delivery_date >= ?", DateTime.now.getutc)

  #build up the producers hash, which has email as key and postings array as value
  postings.each do |posting|
    days_until_delivery = (posting.delivery_date - DateTime.now.getutc) / (60*60*24)
    #here's we're filtering out all postings whose delivery date is other than 1-2 days in the future
    if days_until_delivery > 1.0 && days_until_delivery < 2.0
      if producers[posting.user.email].nil?
        producers[posting.user.email] = []
      end
      producers[posting.user.email] << posting
    end
  end

  producers.each do |email, postings|
    ProducerNotificationsMailer.current_orders(email, postings).deliver_now
    ProducerNotificationsMailer.current_orders("david@farmerscellar.com", postings).deliver_now
  end

  puts "done."

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