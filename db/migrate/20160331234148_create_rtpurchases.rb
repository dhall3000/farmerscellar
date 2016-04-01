class CreateRtpurchases < ActiveRecord::Migration
  def change
    create_table :rtpurchases do |t|
      t.boolean :success
      t.string :message
      t.string :correlation_id
      t.string :rtba_id
      t.float :gross_amount
      t.float :fee_amount
      t.string :ack
      t.string :error_code

      t.timestamps null: false
    end
  end
end
