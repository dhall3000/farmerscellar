class CreateBpPpMpErrors < ActiveRecord::Migration
  def change
    create_table :bp_pp_mp_errors, id: false do |t|
      t.references :bulk_payment, index: true
      t.references :pp_mp_error, index: true

      t.timestamps null: false
    end
    add_foreign_key :bp_pp_mp_errors, :bulk_payments
    add_foreign_key :bp_pp_mp_errors, :pp_mp_errors
  end
end
