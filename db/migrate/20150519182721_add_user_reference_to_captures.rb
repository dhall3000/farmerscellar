class AddUserReferenceToCaptures < ActiveRecord::Migration
  def change
    add_reference :captures, :admin, index: true
    #add_foreign_key :captures, :users, name: "admin_id"
  end
end
