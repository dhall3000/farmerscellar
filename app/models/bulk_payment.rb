class BulkPayment < ActiveRecord::Base
  has_many :bulk_payment_payables
  has_many :payment_payables, through: :bulk_payment_payables

  has_many :bp_pp_mp_commons
  has_many :pp_mp_commons, through: :bp_pp_mp_commons

  has_many :bp_pp_mp_errors
  has_many :pp_mp_errors, through: :bp_pp_mp_errors
end
