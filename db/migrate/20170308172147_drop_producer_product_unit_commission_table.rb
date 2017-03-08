class DropProducerProductUnitCommissionTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :producer_product_unit_commissions
  end
end