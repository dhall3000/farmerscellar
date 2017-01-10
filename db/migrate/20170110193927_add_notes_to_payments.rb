class AddNotesToPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :payments, :notes, :text
  end
end