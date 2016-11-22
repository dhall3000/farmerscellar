class CreateCreditorObligations < ActiveRecord::Migration[5.0]
  def change
    create_table :creditor_obligations do |t|
      t.references :creditor_order, foreign_key: true
      t.float :balance

      t.timestamps
    end
  end
end
