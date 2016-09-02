require 'utility/funds_processing'
require 'utility/bulk_payment_processing'

class RakeHelper

	def self.do_hourly_tasks

	  puts "beginning hourly scheduled tasks..."

	  roll_postings
		do_nightly_tasks
		send_pickup_deadline_reminders

	  puts "finished with hourly tasks."

	end

	private

		def self.roll_postings			
		  transition_posting_ids = transition_open_postings
		  transitioned_tote_item_ids = transition_tote_items_to_committed(transition_posting_ids)	  
			send_orders_to_creditors(transition_posting_ids)		
		end

		def self.send_pickup_deadline_reminders

			puts "send_pickup_deadline_reminders: enter"

			#if this isn't the correct time, exit
			now = Time.zone.now
			if now.wday != FOODCLEAROUTWARNINGDAYTIME[:wday] || now.hour != FOODCLEAROUTWARNINGDAYTIME[:hour]
				puts "send_pickup_deadline_reminders: it is not pickup deadline reminder time so exiting having done nothing."
				puts "send_pickup_deadline_reminders: exit"
				return
			end			

			#get a list of everbody who had products delivered last week

			#here's some hack-a-billy: we want to send a pickup deadline reminder only to folks for whom we have no record of them having picked up after their last goods
			#were delivered. the 'goods' could be either tote items or "partner" goods (e.g. blue valley meats, azure standard etc.). so we need to query up two different lists,
			#one for users with tote items remaining at the dropsite and one for users with partner goods remaining.
			#since i suck at rails querying and db / sql in general i'm going to hack it like this: first do a "filter query" on tote items then do a "filter query" on parter deliveries.
			#a "filter query" just says give me everybody who's had a tote item filled within the last 7 days. then from there i'll refine it with a call to check for if the filling
			#was after the user's last pickup etc.
			#then once i have these two refined "filter queries", i'm going to manually merge them together in to a hash (i.e. goods_at_dropsite_by_user). so when all is said and
			#done you'll be able to go goods_at_dropsite_by_user[UserX][:filled_tote_items] or goods_at_dropsite_by_user[UserX][:partner_deliveries] to get what you're looking for
			#ugly. get 'er' done
			
			filled_within_last_seven_days_users = User.joins(tote_items: :posting).where("postings.delivery_date > ? and tote_items.state = ?", Time.zone.now - 7.days, ToteItem.states[:FILLED]).distinct
			partner_users_with_delivery_last_seven_days = User.joins(:partner_deliveries).where("users.partner_user = ? and partner_deliveries.created_at > ?", true, Time.zone.now - 7.days).distinct

			goods_at_dropsite_by_user = {}

			filled_within_last_seven_days_users.each do |filled_within_last_seven_days_user|
				user = filled_within_last_seven_days_user
				goods_at_dropsite_by_user[user] = {filled_tote_items: user.filled_items_at_dropsite}				
			end

			partner_users_with_delivery_last_seven_days.each do |partner_user_with_delivery_last_seven_days|
				user = partner_user_with_delivery_last_seven_days

				if !goods_at_dropsite_by_user.has_key?(user)
					goods_at_dropsite_by_user[user] = {}
				end

				goods_at_dropsite_by_user[user][:partner_deliveries] = user.partner_deliveries_at_dropsite

			end

			goods_at_dropsite_by_user.each do |user, goods_at_dropsite|

				if (goods_at_dropsite[:filled_tote_items] && goods_at_dropsite[:filled_tote_items].any?) || (goods_at_dropsite[:partner_deliveries] && goods_at_dropsite[:partner_deliveries].any?)
					puts "user #{user.id.to_s} #{user.email} has products remaining. sending them a pickup deadline reminder."
					UserMailer.pickup_deadline_reminder(user, goods_at_dropsite[:filled_tote_items], goods_at_dropsite[:partner_deliveries]).deliver_now					
				end

			end
			
			puts "send_pickup_deadline_reminders: exit"
			
		end

		def self.do_nightly_tasks

			now = Time.zone.now

			last_run = NightlyTaskRun.order("nightly_task_runs.id").last

			if last_run.nil?
				last_run = now - 1.day
			else
				last_run = last_run.created_at
			end

			num_seconds_in_23_and_a_half_hours = 23.5 * 60 * 60
			time_since_last_run = now - last_run

			if time_since_last_run < num_seconds_in_23_and_a_half_hours
				s = JunkCloset.puts_helper("do_nightly_tasks - short circuit - too little time elapsed since last run", "time_since_last_run", time_since_last_run.to_s)
				JunkCloset.puts_helper(s, "last_run", last_run.to_s)
				puts s			
				return
			end

			#we want to do nightly tasks once at 10pm. production wiggles a bit on the exact time the task
			#runs so give a 35 minute window in which to get things done
			min = Time.zone.local(now.year, now.month, now.day, 21, 55)
			max = Time.zone.local(now.year, now.month, now.day, 22, 30)

			if now < min || now > max
				puts JunkCloset.puts_helper("do_nightly_tasks - short circuit - not in the right time window at night", "now", now.to_s)
				return
			end

			#time stamp this run
			NightlyTaskRun.create
			
			puts "do_nightly_tasks start"

			FundsProcessing.do_bulk_customer_purchase
			BulkPaymentProcessing.do_bulk_creditor_payment

			puts "do_nightly_tasks end"

		end	

		def self.transition_open_postings

			puts "transition_open_postings: start"

			postings = Posting.where(state: Posting.states[:OPEN])

			if postings.any?
				puts "transition_open_postings: #{postings.count.to_s} posting(s) to transition to COMMITMENTZONE"
			else
				puts "transition_open_postings: no postings to transition to COMMITMENTZONE"
			end

			transitioned_postings = []

			postings.each do |posting|
				if Time.zone.now >= posting.commitment_zone_start
					puts "transition_open_postings: transitioning posting id #{posting.id.to_s} to COMMITMENTZONE"
					posting.transition(:commitment_zone_started)
					transitioned_postings << posting.id
				end
			end

			puts "transition_open_postings: end "

			return transitioned_postings.uniq

		end

		def self.transition_tote_items_to_committed(transitioned_postings)

			puts "transition_tote_items_to_committed: start"

			postings = Posting.where(id: transitioned_postings)

			transitioned_tote_item_ids = []

			postings.each do |posting|

				puts "transition_tote_items_to_committed: now transitioning tote items to COMMITTED for posting id #{posting.id.to_s}"
				
				tote_items_to_transition = posting.tote_items.where(state: ToteItem.states[:AUTHORIZED])

				if !tote_items_to_transition.any?
					puts "transition_tote_items_to_committed: there are no tote items associated with posting id #{posting.id.to_s} that need to be transitioned to COMMITTED"
				end

				tote_items_to_transition.each do |tote_item_to_transition|

					if tote_item_to_transition.posting.commitment_zone_start.nil?
		      	next
		    	end

			    if Time.zone.now >= tote_item_to_transition.posting.commitment_zone_start
			    	puts "transition_tote_items_to_committed: transitioning tote_item id #{tote_item_to_transition.id.to_s} to COMMITTED"
					  tote_item_to_transition.transition(:commitment_zone_started)
					  transitioned_tote_item_ids << tote_item_to_transition.id
			    end
				end

			end

			puts "transition_tote_items_to_committed: end"

			return transitioned_tote_item_ids

		end

		def self.send_orders_to_creditors(posting_ids)

			puts "send_orders_to_creditors: start"

		  if posting_ids.nil? || !posting_ids.any?
		    puts "send_orders_to_creditors: no postings transitioned. all done."
		    return
		  end

		  postings = Posting.find(posting_ids.uniq)

		  creditors = {}
		  postings.each do |posting|

		  	creditor = posting.user.get_creditor

		  	if !creditors.has_key?(creditor)
		  		creditors[creditor] = []
		  	end

		  	creditors[creditor] << posting

		  end

		  creditors.each do |creditor, postings|
		  	send_order_to_creditor(creditor, postings)
		  end

		  puts "send_orders_to_creditors: end"

		end

		#the postings sent in as param should be right at their order cutoff
		def self.send_order_to_creditor(creditor, postings_in_transition)

			puts "send_order_to_creditor: start"

			postings = postings_in_transition

			if creditor.nil? || postings.nil?
				AdminNotificationMailer.general_message("MAJOR PROBLEM: send_order_to_creditor error", "creditor or postings params were nil").deliver_now
				return
			end

			bi = creditor.get_business_interface

			if bi.nil?
				msg_body = "Trying to send order to #{creditor.farm_name} but they have no business interface. Unable to submit order!"
				AdminNotificationMailer.general_message("MAJOR PROBLEM: send_order_to_creditor error", msg_body).deliver_now
				return
			else
				puts "send_order_to_creditor: sending order to #{creditor.get_business_interface.name}"
			end
			
	    orderable_report = creditor.get_postings_orderable(postings)

	    if orderable_report.nil?
	    	msg_body = "orderable_report is nil"
	    	AdminNotificationMailer.general_message("MAJOR PROBLEM: send_order_to_creditor error", msg_body).deliver_now
	    	return
	    end

	    producer_net_total = orderable_report[:postings_total_producer_net]
	    postings_orderable = orderable_report[:postings_to_order]
	    postings_closeable = orderable_report[:postings_to_close]

	    if creditor.order_minimum_met?(producer_net_total)	    	
		  	puts "send_order_to_creditor: sending order for #{postings_orderable.count.to_s} posting(s) to #{bi.name}"
		  	ProducerNotificationsMailer.current_orders(creditor, postings_orderable).deliver_now
	    end

	    postings_closeable.each do |posting_closeable|
	  		#close out the posting so admin doesn't have to deal with it.
	  		#here at the order cutoff is the time to close out the posting so that admin doesn't have to see it on their
	  		#radar screen. or is this the right time? say that order cutoff is on monday and delivery friday. but say on wednesday we also have some
	  		#products being delivered. if we close out this posting due to insufficient quantity on monday then on wednesday the delivery notification
	  		#would go out to the user. this might be confusing. on the other hand, the unfilled folks might want to know earlier rather than later so
	  		#they can take measures to procure similar such food elsehow.
	  		posting_closeable.fill(0)
	    end
	    
			puts "send_order_to_creditor: end"
		end

		def self.get_commit_totes_email_body(tote_item_ids)

		  body = ""

		  if tote_item_ids.nil?
		    body = "empty body"
		  else
		    body = "number of tote_items transitioned from AUTHORIZED -> COMMITTED: #{tote_item_ids.count}. tote_item ids transitioned: #{tote_item_ids.to_s}."
		  end

		  return body
		  
		end

end