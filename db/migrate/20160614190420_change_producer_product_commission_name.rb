class ChangeProducerProductCommissionName < ActiveRecord::Migration
  def change
    rename_table :producer_product_commissions, :producer_product_unit_commissions
  end
end
