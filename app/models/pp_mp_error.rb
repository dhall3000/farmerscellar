class PpMpError < ApplicationRecord
  has_many :bp_pp_mp_errors
  has_many :bulk_payments, through: :bp_pp_mp_errors
end
