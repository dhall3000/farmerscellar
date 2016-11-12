class CreateCreditorOrderPostings < ActiveRecord::Migration[5.0]
  def change
    create_table :creditor_order_postings do |t|
      t.references :creditor_order, foreign_key: true
      t.references :posting, foreign_key: true

      t.timestamps
    end
  end
end
