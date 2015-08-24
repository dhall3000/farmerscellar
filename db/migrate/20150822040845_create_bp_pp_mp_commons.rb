class CreateBpPpMpCommons < ActiveRecord::Migration
  def change
    create_table :bp_pp_mp_commons, id: false do |t|
      t.references :bulk_payment, index: true
      t.references :pp_mp_common, index: true

      t.timestamps null: false
    end
    add_foreign_key :bp_pp_mp_commons, :bulk_payments
    add_foreign_key :bp_pp_mp_commons, :pp_mp_commons
  end
end
