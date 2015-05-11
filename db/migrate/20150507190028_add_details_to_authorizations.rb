class AddDetailsToAuthorizations < ActiveRecord::Migration
  def change
    add_column :authorizations, :express_token, :string
    add_column :authorizations, :payer_id, :string
  end
end
