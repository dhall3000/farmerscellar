class RemoveEmailFromPayments < ActiveRecord::Migration
  def change
  	remove_column :payments, :email
  end
end
