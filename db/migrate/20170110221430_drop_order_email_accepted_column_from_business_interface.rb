class DropOrderEmailAcceptedColumnFromBusinessInterface < ActiveRecord::Migration[5.0]
  def change
    remove_column :business_interfaces, :order_email_accepted
  end
end