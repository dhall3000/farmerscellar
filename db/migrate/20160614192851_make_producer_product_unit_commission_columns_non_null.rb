class MakeProducerProductUnitCommissionColumnsNonNull < ActiveRecord::Migration
  def change
    change_column :producer_product_unit_commissions, :user_id, :integer, null: false
    change_column :producer_product_unit_commissions, :product_id, :integer, null: false
    change_column :producer_product_unit_commissions, :commission, :float, null: false
  end
end
