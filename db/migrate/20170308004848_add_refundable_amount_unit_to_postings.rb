class AddRefundableAmountUnitToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :refundable_amount_unit_producer_to_fc, :float, default: 0
    change_column_null :postings, :refundable_amount_unit_producer_to_fc, false, 0
  end
end