class PostingsController < ApplicationController
  def new
  	#@posting = Posting.new(user_id: current_user.id)  	
  	@posting = current_user.postings.new
  	@products = Product.all
  	@unit_categories = UnitCategory.all
  	@unit_kinds = UnitKind.all
  end
end
