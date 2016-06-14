class AddIdToProducerProductCommissions < ActiveRecord::Migration
  def change
    add_column :producer_product_commissions, :id, :primary_key
  end
end
