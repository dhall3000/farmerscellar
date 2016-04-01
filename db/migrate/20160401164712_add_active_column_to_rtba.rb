class AddActiveColumnToRtba < ActiveRecord::Migration
  def change
    add_column :rtbas, :active, :boolean
  end
end
