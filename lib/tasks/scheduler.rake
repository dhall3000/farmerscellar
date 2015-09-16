desc "This task is called by the Heroku scheduler add-on"

task :commit_totes => :environment do

  puts "comitting totes..."

  tote_items = ToteItem.where(status: ToteItem.states[:AUTHORIZED])

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
	  end

  end

  puts "done."

end

task :mailer_test => :environment do
  AdminNotificationMailer.general_message("test subject", "this is the body").deliver_now
end