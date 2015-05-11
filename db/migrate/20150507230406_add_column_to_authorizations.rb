class AddColumnToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :amount, :float
  end
end
