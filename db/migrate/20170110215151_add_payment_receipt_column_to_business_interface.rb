class AddPaymentReceiptColumnToBusinessInterface < ActiveRecord::Migration[5.0]
  def change
    
    add_column :business_interfaces, :payment_receipt_email, :string

    BusinessInterface.all.each do |bi|
      bi.update(payment_receipt_email: bi.order_email)
    end

  end
end