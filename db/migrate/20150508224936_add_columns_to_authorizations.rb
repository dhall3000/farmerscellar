class AddColumnsToAuthorizations < ActiveRecord::Migration
  def change
  	add_column :authorizations, :correlation_id, :string
  	add_column :authorizations, :transaction_id, :string
  	add_column :authorizations, :payment_date, :datetime
  	add_column :authorizations, :gross_amount, :float
  	add_column :authorizations, :gross_amount_currency_id, :string
  	add_column :authorizations, :payment_status, :string
  	add_column :authorizations, :pending_reason, :string  	
  end
end