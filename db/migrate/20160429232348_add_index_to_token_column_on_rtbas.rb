class AddIndexToTokenColumnOnRtbas < ActiveRecord::Migration
  def change
  	add_index :rtbas, :token
  end
end
