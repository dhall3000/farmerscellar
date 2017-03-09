class RemovePaymentInstructionsColumnFromBusinessInterface < ActiveRecord::Migration[5.0]
  def change
    remove_column :business_interfaces, :payment_instructions
  end
end