class CreateRtpurchasePrs < ActiveRecord::Migration
  def change
    create_table :rtpurchase_prs, id: false do |t|
      t.references :rtpurchase, index: true
      t.references :purchase_receivable, index: true

      t.timestamps null: false
    end
    add_foreign_key :rtpurchase_prs, :rtpurchases
    add_foreign_key :rtpurchase_prs, :purchase_receivables
  end
end
