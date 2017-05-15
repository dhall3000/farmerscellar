class AddRefundableDepositColumnToPosting < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :refundable_deposit, :float
    add_column :postings, :refundable_deposit_instructions, :text
  end
end
