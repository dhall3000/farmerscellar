class AddPaymentMethodAndTimeColumnsToBusinessInterface < ActiveRecord::Migration[5.0]
  def change

    add_column :business_interfaces, :payment_method, :integer, default: 0
    add_column :business_interfaces, :payment_time, :integer, default: 2

    BusinessInterface.all.each do |bi|
      if bi.paypal_accepted
        bi.payment_method = 0
        bi.payment_time = 2
      else
        bi.payment_method = 1
        bi.payment_time = 0
      end
    end

    change_column :business_interfaces, :payment_method, :integer, default: 0, null: false
    change_column :business_interfaces, :payment_time, :integer, default: 2, null: false

  end
end