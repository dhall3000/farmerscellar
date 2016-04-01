class ChangeColumnConstraintsOnRtauthorizations < ActiveRecord::Migration
  def change
  	change_column :rtauthorizations, :rtba_id, :integer, null: false
  end
end
