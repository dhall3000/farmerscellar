class FundsProcessing

	def self.bulk_buy_new

		ret = {}

  	ret[:filled_tote_items] = ToteItem.where(status: ToteItem.states[:FILLED])  	

    user_ids = ret[:filled_tote_items].select(:user_id).distinct    
    ret[:user_infos] = []
    ret[:total_bulk_buy_amount] = 0

    for user_id in user_ids
      user_info = {total_amount: 0, name: ''}
      tote_items_by_user = ret[:filled_tote_items].where(user_id: user_id.user_id)
      for tote_item_by_user in tote_items_by_user
        user_info[:total_amount] = (user_info[:total_amount] + (tote_item_by_user.quantity * tote_item_by_user.price).round(2)).round(2)
        user_info[:name] = tote_item_by_user.user.name
      end
      ret[:total_bulk_buy_amount] = (ret[:total_bulk_buy_amount] + user_info[:total_amount]).round(2)
      ret[:user_infos] << user_info
    end

    return ret

	end

end