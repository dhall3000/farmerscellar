class ChangeUnitColumnInProducerProductUnitCommissions < ActiveRecord::Migration
  def change
    change_column_null :producer_product_unit_commissions, :unit_id, false
  end
end