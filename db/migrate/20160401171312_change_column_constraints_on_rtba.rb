class ChangeColumnConstraintsOnRtba < ActiveRecord::Migration
  def change
  	change_column :rtbas, :token, :string, null: false
  	change_column :rtbas, :ba_id, :string, null: false
  	change_column :rtbas, :user_id, :integer, null: false
  	change_column :rtbas, :active, :boolean, default: false, null: false
  end
end