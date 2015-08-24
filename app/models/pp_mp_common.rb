class PpMpCommon < ActiveRecord::Base
  has_many :bp_pp_mp_commons
  has_many :bulk_payments, through: :bp_pp_mp_commons
end
