class AddNotNullConstraintToPostingsDescription < ActiveRecord::Migration
  def up
  	change_column :postings, :description, :string, null: false
  end
end
