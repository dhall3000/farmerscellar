class RemoveQuantityAvailableColumnFromPostings < ActiveRecord::Migration[5.0]
  def change
    remove_column :postings, :quantity_available
  end
end