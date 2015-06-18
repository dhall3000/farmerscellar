class Purchase < ActiveRecord::Base
  serialize :response

  has_many :purchase_purchase_receivables
  has_many :purchase_receivables, through: :purchase_purchase_receivables
end
