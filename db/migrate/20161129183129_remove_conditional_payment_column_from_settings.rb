class RemoveConditionalPaymentColumnFromSettings < ActiveRecord::Migration[5.0]
  def change
    remove_column :settings, :conditional_payment
  end
end