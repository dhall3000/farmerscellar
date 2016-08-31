class AdminBulkBuy < ApplicationRecord
  belongs_to :admin, class_name: "User", foreign_key: "user_id"
  belongs_to :bulk_buy
end
