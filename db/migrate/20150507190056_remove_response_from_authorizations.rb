class RemoveResponseFromAuthorizations < ActiveRecord::Migration
  def change
  	remove_column :authorizations, :response, :text
  end
end
