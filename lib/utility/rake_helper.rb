require 'utility/funds_processing'
require 'utility/bulk_payment_processing'

class RakeHelper

	def self.do_hourly_tasks

	  puts "beginning hourly scheduled tasks..."

	  roll_postings
		do_nightly_tasks
		send_pickup_deadline_reminders
    send_postings_receivable_to_admin

	  puts "finished with hourly tasks."

	end

	private

		def self.roll_postings			
		  transition_posting_ids = transition_open_postings
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

			#this is all the customers that had FC-sourced product delivered in the last 7 days						
			filled_within_last_seven_days_users = User.select("users.id, users.email").joins(tote_items: :posting).where("postings.delivery_date > ? and tote_items.state = ?", Time.zone.now - 7.days, ToteItem.states[:FILLED]).distinct
			#this is all the customers that had non-FC-sourced (i.e. partner source (e.g. Azure Standard, Blue Valley Meats etc)) products delivered in the last 7 days
			partner_users_with_delivery_last_seven_days = User.select("users.id, users.email").joins(:partner_deliveries).where("users.partner_user = ? and partner_deliveries.created_at > ?", true, Time.zone.now - 7.days).distinct

			#HACK! I don't know how to do this in a fancy / fast way so I'm just going to hack it. basically all I want to do is take the above two relations and merge them
			#so that i end up with a list of distinct users who had product delivered within the last 7 days, regardless of if they had fc products, partner products or both.
			#so that's what all the rest of this junk is

			last_weeks_customers = {}

			filled_within_last_seven_days_users.each do |filled_within_last_seven_days_user|
				last_weeks_customers[filled_within_last_seven_days_user] = nil
			end

			partner_users_with_delivery_last_seven_days.each do |partner_user_with_delivery_last_seven_days|
				
				if !last_weeks_customers.has_key?(partner_user_with_delivery_last_seven_days)
					last_weeks_customers[partner_user_with_delivery_last_seven_days] = nil
				end

			end

			last_weeks_customers.each do |last_weeks_customer, val|
				last_weeks_customer.send_pickup_deadline_reminder_email
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

      postings = Posting.where("state = ? AND commitment_zone_start <= ?", Posting.states[:OPEN], Time.zone.now)
      puts "transition_open_postings: #{postings.count.to_s} OPEN posting(s)"

      transitioned_postings = []

      postings.each do |posting|
        puts "transition_open_postings: transitioning posting id #{posting.id.to_s} to COMMITMENTZONE"
        posting.transition(:commitment_zone_started)
        transitioned_postings << posting.id
      end

      puts "transition_open_postings: end "

      return transitioned_postings.uniq

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

		  	creditor = posting.get_creditor
		  	order_cutoff = posting.commitment_zone_start

		  	if !creditors[creditor]
		  		creditors[creditor] = {}
		  	end

		  	if !creditors[creditor][order_cutoff]
		  		creditors[creditor][order_cutoff] = true		  		
		  	end

		  end

		  creditors.each do |creditor, order_cutoffs|
		  	send_order_to_creditor(creditor, order_cutoffs)
		  end

		  puts "send_orders_to_creditors: end"

		end

		#the postings sent in as param should be right at their order cutoff
		def self.send_order_to_creditor(creditor, order_cutoffs)

			puts "send_order_to_creditor: start"

			if creditor.nil? || order_cutoffs.nil?
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

      postings_for_creditor_order = []
      total_producer_net = 0.0

			order_cutoffs.each do |order_cutoff, ignore_value|

        order_report = creditor.outbound_order_report(order_cutoff)

        #{postings_order_requirements_met: postings_order_requirements_met, postings_order_requirements_unmet: postings_order_requirements_unmet, order_value_producer_net: order_value_producer_net}
        postings_orderable = order_report[:postings_order_requirements_met]
        postings_closeable = order_report[:postings_order_requirements_unmet]

        postings_for_creditor_order += postings_orderable
        total_producer_net = (total_producer_net + order_report[:order_value_producer_net]).round(2)

        puts "send_order_to_creditor: sending order for #{postings_orderable.count.to_s} posting(s) to #{bi.name}"
        ProducerNotificationsMailer.current_orders(creditor, postings_orderable).deliver_now

        postings_closeable.each do |posting_closeable|
          #close out the posting so admin doesn't have to deal with it.
          #here at the order cutoff is the time to close out the posting so that admin doesn't have to see it on their
          #radar screen. or is this the right time? say that order cutoff is on monday and delivery friday. but say on wednesday we also have some
          #products being delivered. if we close out this posting due to insufficient quantity on monday then on wednesday the delivery notification
          #would go out to the user. this might be confusing. on the other hand, the unfilled folks might want to know earlier rather than later so
          #they can take measures to procure similar such food elsehow.
          posting_closeable.fill(0)
        end

			end

      if postings_for_creditor_order.any?
        delivery_date = postings_for_creditor_order.first.delivery_date
        CreditorOrder.create(creditor: creditor, delivery_date: delivery_date, postings: postings_for_creditor_order, order_value_producer_net: total_producer_net)
      end
	    
			puts "send_order_to_creditor: end"

		end

    def self.send_postings_receivable_to_admin
      
      puts "send_postings_receivable_to_admin: enter"

      #if this isn't the correct time, exit
      now = Time.zone.now
      if now.hour != 2
        puts "send_postings_receivable_to_admin: it's not 2AM so quitting."
        puts "send_postings_receivable_to_admin: exit"
        return        
      end

      delivery_date = now.midnight
      postings_by_creditor = {}

      #you'll have one row for each creditor/order_cutoff combo. we want to mash these in to one per creditor/delivery_date combo      
      CreditorOrder.where(delivery_date: delivery_date).each do |creditor_order|

        if postings_by_creditor[creditor_order.creditor].nil?
          postings_by_creditor[creditor_order.creditor] = creditor_order.postings.to_a
        else
          postings_by_creditor[creditor_order.creditor] += creditor_order.postings.to_a
        end

      end

      if postings_by_creditor.count > 0
        puts "send_postings_receivable_to_admin: there were #{postings_by_creditor.count.to_s} orders receivable for today. sending email to admin."
        AdminNotificationMailer.receiving(postings_by_creditor, delivery_date).deliver_now
      else
        puts "send_postings_receivable_to_admin: there were 0 orders receivable for today"      
      end

      puts "send_postings_receivable_to_admin: exit"

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