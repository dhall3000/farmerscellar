class ChangeUserDistributorAccountType < ActiveRecord::Migration
  def change
    User.where(account_type: 4).each do |distributor|
      distributor.update(account_type: 1)
    end
  end
end
