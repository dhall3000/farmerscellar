class AddPartnerUserColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :partner_user, :boolean, default: false
  end
end
