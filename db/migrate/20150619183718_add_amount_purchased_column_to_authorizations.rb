class AddAmountPurchasedColumnToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :amount_purchased, :float
  end
end
