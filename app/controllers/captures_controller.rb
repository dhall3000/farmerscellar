class CapturesController < ApplicationController
  def index
  	#TODO: eventually we're going to want to provide a list of historical captures for an admin to view
  	#and the top-most capture should be for 'today'. a 'capture', then is really just a bucket of tote items for which we
  	#captured payment on a given day. that is, a capture is all the payments captured from midnight to midnight.

  	#to begin with we won't have any 'historical' captures/payments. so we'll just spoof it by taking the last 7 days
  	#@recent_captures = ((Date.today - 7)..Date.today).to_a.reverse

  	#actually, screw it. we'll do viewing of historical captures at a later date. for now we're just going to do new captures and move on.

  end

  def new
  	#pull up all the tote_items that would be in this proposed new capture
  	#attach them to the .tote_items member
  	#set the .admin_id value
  	#render view
  	admin = User.find(current_user.id)
  	if admin != nil && admin.account_type == 2
  	  @capture = Capture.new(admin: admin)
  	  #@tote_items = ToteItem.where(status: ToteItem.states[:FILLED]).order("user_id")
  	  @tote_items = ToteItem.where(status: ToteItem.states[:FILLED])
    end
    
  	if @capture != nil && @tote_items != nil
  	  @tote_items.each do |tote_item|
  	  	@capture.tote_items << tote_item
  	  end
  	  #@capture.save
  	end    

  	#debugger

  end

  def create
  	#debugger
  end

  def edit
  end

  def update
  end
end
