class AddProducerNetUnitColumnToPostings < ActiveRecord::Migration[5.0]
  def change
    add_column :postings, :producer_net_unit, :float, default: 0, null: false
  end
end