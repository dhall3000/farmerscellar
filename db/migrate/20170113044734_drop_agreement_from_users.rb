class DropAgreementFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :agreement
  end
end