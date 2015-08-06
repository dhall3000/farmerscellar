class ChangeZipOnUsers < ActiveRecord::Migration
  def change
  	change_column :users, :zip, :integer
  end
end
