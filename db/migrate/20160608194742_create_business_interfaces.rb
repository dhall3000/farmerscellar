class CreateBusinessInterfaces < ActiveRecord::Migration
  def change
    create_table :business_interfaces do |t|
      t.string :name, null: false
      t.boolean :order_email_accepted
      t.string :order_email
      t.string :order_instructions
      t.boolean :paypal_accepted
      t.string :paypal_email
      t.string :payment_instructions
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :business_interfaces, :users

    #for initial migration just populate the necessary business interface class with existing producer's info
    producers = User.where(account_type: User.types[:PRODUCER])
    producers.each do |producer|
      producer.create_business_interface(name: producer.farm_name, order_email_accepted: true, order_email: producer.email, paypal_accepted: true, paypal_email: producer.email)
    end    

  end
end
