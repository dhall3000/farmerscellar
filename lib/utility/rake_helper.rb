require 'utility/funds_processing'
require 'utility/bulk_payment_processing'

class RakeHelper

	def self.do_hourly_tasks

	  puts "beginning hourly scheduled tasks..."

	  roll_postings
		do_nightly_tasks
		send_pickup_deadline_reminders
    send_postings_receivable_to_admin
    do_db_integrity_checks
    keep_garage_door_opener_alive

	  puts "finished with hourly tasks."

	end

	private

    #what is the deal with this? currently (2017-04-29) we're in prototype mode using the garage of david hall's house as the dropsite. been having a vexatious
    #time trying to get the door to be reliable for customers. the symptoms were customers would poke, stab and hack at the buttons on the kiosk with mixed results.
    #sometimes it would be flawless. sometimes it would open after 5 - 20 seconds. sometimes it wouldn't open at all. of course, doesn't help that users would
    #keep poking away at the button, exacerbating the problem. first i thought it was the super cheap, slow android tab. got a nicer one. that improved things somewhat.
    #then i figured it was a network issue....the tab sends message to router 1, goes through router 2 up to FC server, then back to router 2 then port-forwarded to
    #router 1, then to the garagedoorbuddy device to open the door. so i decided to put the kiosk tab on the same router (i.e. "router1") as the GDB device and change the
    #kiosk's "open/close door" button to point straight at the GDB device. this is a massive improvement...when it works. that is, when it works it is instantaneous whereas
    #the previous setup would be ~500ms delay best case scenario. however, there has been at least one incident where a user was not able to open the door at all. oh, i also
    #tried cleaning the kiosk with a baby wipe. that could have improved things so i should do that more. so now i'm wondering if a 'keep alive' is needed...perhaps the
    #wifi connection is dropping between router1 <-> GDB device or perhaps GDB goes to sleep after some time. a good argument against this, however, is that when i observed the one
    #recent customer unable to get in with the new setup i poked my admin "toggle door" button and the door opened immediately. this suggests the wifi connection was fine and
    #the GDB device was awake.
    #all things considered, it might be most likely that simply keeping the tab clean is the deal.
    #nevertheless, putting this simple code in to ping the GDB device once per hour. we'll see if things improve...
    #also, note that i'm intentionally pinging the wrong "door". with GDB you can control two different doors with the http GET params. like this:
    #http://[IP address]:1984/client?command=door1
    #http://[IP address]:1984/client?command=door2
    #'door2' is the actual door. 'door1' is not hooked to anything but the GDB device doesn't know that and will attempt to open that 'door' anyway so here we're pinging the
    #phantom door to keep GDB alive.
    def self.keep_garage_door_opener_alive
      
      puts "RakeHelper.keep_garage_door_opener_alive start"

      if Rails.env.production?

        http = Net::HTTP.new(Dropsite.first.ip_address, 1984)
        http.open_timeout = 10
        http.read_timeout = 10
        response = nil
        #flash_message = "If the garage door isn't working please knock on the front door for help."

        begin
          response = http.get("/client?command=door1")
        rescue Net::ReadTimeout => e1
          #flash.now[:danger] = flash_message
          puts "RakeHelper.keep_garage_door_opener_alive timeout. e1.message = #{e1.message}"
        rescue Net::OpenTimeout => e2
          #flash.now[:danger] = flash_message
          puts "RakeHelper.keep_garage_door_opener_alive timeout. e2.message = #{e2.message}"
        end

        if response
          puts "RakeHelper.keep_garage_door_opener_alive response: #{response.class.to_s}"
        else
          puts "RakeHelper.keep_garage_door_opener_alive response is nil"
        end      

      end

      puts "RakeHelper.keep_garage_door_opener_alive end"    
      
    end

    def self.do_db_integrity_checks
      producers = User.where(account_type: User.types[:PRODUCER])
      no_interface_producers = []

      producers.each do |producer|
        if producer.get_business_interface.nil?
          no_interface_producers << producer
        end
      end

      if no_interface_producers.any?
        body_lines = ["Here is a list of producers that have no associated business_interface"]
        no_interface_producers.each do |nip|
          body_lines << "ID: #{nip.id.to_s}, farm_name: #{nip.farm_name}"
        end
        AdminNotificationMailer.general_message("MAJOR PROBLEM: producer(s) without associated business_interface", "fake body", body_lines).deliver_now        
      end
    end

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
				last_run = now - 24.hours
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

      #dirty up everybody's header bit so that headers refresh after the end of the day
      User.update_all(header_data_dirty: true)

			#time stamp this run
			NightlyTaskRun.create
			
			puts "do_nightly_tasks start"

			FundsProcessing.do_bulk_customer_purchase
			BulkPaymentProcessing.do_bulk_creditor_payment

			puts "do_nightly_tasks end"

		end	

    def self.transition_open_postings

      puts "transition_open_postings: start"

      postings = Posting.where("state = ? AND order_cutoff <= ?", Posting.states[:OPEN], Time.zone.now)
      puts "transition_open_postings: #{postings.count.to_s} OPEN posting(s)"

      transitioned_postings = []

      postings.each do |posting|
        puts "transition_open_postings: transitioning posting id #{posting.id.to_s} to COMMITMENTZONE"
        posting.transition(:order_cutoffed)
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
		  	order_cutoff = posting.order_cutoff

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

			order_cutoffs.each do |order_cutoff, ignore_value|

        order_report = creditor.outbound_order_report(order_cutoff)

        #{postings_order_requirements_met: postings_order_requirements_met, postings_order_requirements_unmet: postings_order_requirements_unmet, order_value_producer_net: order_value_producer_net}
        postings_orderable = order_report[:postings_order_requirements_met]
        postings_closeable = order_report[:postings_order_requirements_unmet]
        order_value_producer_net = order_report[:order_value_producer_net]

        if postings_orderable && postings_orderable.any?                  
          CreditorOrder.submit(postings_orderable)
        end

        if postings_closeable && postings_closeable.any?
          Posting.close(postings_closeable)
        end

			end
	    
			puts "send_order_to_creditor: end"

		end

    def self.send_postings_receivable_to_admin
      
      puts "send_postings_receivable_to_admin: enter"

      #if this isn't the correct time, exit
      now = Time.zone.now
      if now.hour != 3
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