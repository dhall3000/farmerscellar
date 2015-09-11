class AddResponseColumnToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :response, :text
  end
end
