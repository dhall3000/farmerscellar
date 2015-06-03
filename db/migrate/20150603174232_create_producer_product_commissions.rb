class CreateProducerProductCommissions < ActiveRecord::Migration
  def change
    create_table :producer_product_commissions, id: false do |t|
      t.references :product, index: true
      t.references :user, index: true
      t.float :commission

      t.timestamps null: false
    end
    add_foreign_key :producer_product_commissions, :products
    add_foreign_key :producer_product_commissions, :users
  end
end
