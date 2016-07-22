require 'utility/funds_processing'
require 'utility/bulk_payment_processing'

class RakeHelper

	def self.do_hourly_tasks

	  puts "beginning hourly scheduled tasks..."

	  roll_postings
		do_nightly_tasks

	  puts "finished with hourly tasks."

	end

	private

		def self.roll_postings			
		  transition_posting_ids = transition_open_postings
		  transitioned_tote_item_ids = transition_tote_items_to_committed(transition_posting_ids)	  
			send_orders_to_producers(transition_posting_ids)		
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

		def self.send_orders_to_producers(posting_ids)

			puts "send_orders_to_producers: start"

		  if posting_ids.nil? || !posting_ids.any?
		    puts "send_orders_to_producers: no postings transitioned. all done."
		    return
		  end

		  postings = Posting.find(posting_ids.uniq)

		  creditors = {}
		  postings.each do |posting|

		  	creditor = posting.user.get_creditor

		  	if !creditors.has_key?(creditor)
		  		creditors[creditor] = []
		  	end

		  	if posting.submit_order_to_creditor?
		  		creditors[creditor] << posting
		  	else		  		
		  		#close out the posting so admin doesn't have to deal with it.
		  		#here at the order cutoff is the time to close out the posting so that admin doesn't have to see it on their
		  		#radar screen. or is this the right time? say that order cutoff is on monday and delivery friday. but say on wednesday we also have some
		  		#products being delivered. if we close out this posting due to insufficient quantity on monday then on wednesday the delivery notification
		  		#would go out to the user. this might be confusing. on the other hand, the unfilled folks might want to know earlier rather than later so
		  		#they can take measures to procure similar such food elsehow.
		  		posting.fill(0)
		  	end

		  end

		  creditors.each do |creditor, postings|
		  	puts "send_orders_to_producers: sending order for #{postings.count.to_s} posting(s) to #{creditor.email}"
		  	ProducerNotificationsMailer.current_orders(creditor, postings).deliver_now
		  end

		  puts "send_orders_to_producers: end"

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