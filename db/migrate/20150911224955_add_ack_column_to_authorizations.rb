class AddAckColumnToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :ack, :string
  end
end
