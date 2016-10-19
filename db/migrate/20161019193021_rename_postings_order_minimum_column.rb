class RenamePostingsOrderMinimumColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :postings, :order_minimum, :order_minimum_producer_net
  end
end
