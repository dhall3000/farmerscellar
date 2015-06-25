class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :email
      t.float :amount

      t.timestamps null: false
    end
  end
end
