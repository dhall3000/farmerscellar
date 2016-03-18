require 'utility/funds_processing'

class RakeHelper

	def self.do_hourly_tasks

	  puts "beginning hourly scheduled tasks..."

	  transitioned_tote_items_and_postings = transition_tote_items_to_committed_state
		report_committed_tote_items_to_admin(transitioned_tote_items_and_postings[:tote_item_ids])
		send_orders_to_producers(transitioned_tote_items_and_postings[:posting_ids])

	  puts "finished with hourly tasks."

	end

	def self.do_nightly_tasks
		
		puts "do_nightly_tasks start"

		FundsProcessing.do_bulk_customer_purchase

		puts "do_nightly_tasks end"

	end

	def self.do_week_end_tasks
		
		puts "do_week_end_tasks start"

		do_producer_payments

		puts "do_week_end_tasks end"

	end

	private

		def self.do_producer_payments
		end

		def self.send_orders_to_producers(posting_ids)

		  if posting_ids.nil? || !posting_ids.any?
		    puts "send_orders_to_producers: no postings transitioned. all done."
		    return
		  end

		  postings = Posting.find(posting_ids.uniq)
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

		end

		def self.transition_tote_items_to_committed_state

 		  tote_item_ids = []
		  posting_ids = []
			transitioned_tote_items_and_postings = {tote_item_ids: tote_item_ids, posting_ids: posting_ids}

		  tote_items = ToteItem.where(status: ToteItem.states[:AUTHORIZED])

		  if tote_items.count == 0
		    puts "transition_tote_items_to_committed_state: no authorized totes so nothing to transition to committed. all done."
		    return transitioned_tote_items_and_postings
		  end

		  tote_items.each do |tote_item|

		    if tote_item.posting.commitment_zone_start.nil?
		      next
		    end

		    if Time.zone.now >= tote_item.posting.commitment_zone_start
				  tote_item.update(status: ToteItem.states[:COMMITTED])
				  tote_item_ids << tote_item.id
				  posting_ids << tote_item.posting.id
		    end

		  end

		  return transitioned_tote_items_and_postings

		end

		def self.report_committed_tote_items_to_admin(tote_item_ids)

			if !tote_item_ids.nil? && tote_item_ids.any?
		    #send job summary report to admin
		    subject = "commit_totes job summary report"
		    body = get_commit_totes_email_body(tote_item_ids)
		    AdminNotificationMailer.general_message(subject, body).deliver_now
		  end
		  
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