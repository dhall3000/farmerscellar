class AddIpAddressColumnToDropsites < ActiveRecord::Migration[5.0]
  def change
    add_column :dropsites, :ip_address, :string
  end
end
