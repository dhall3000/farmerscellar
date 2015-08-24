class BpPpMpCommon < ActiveRecord::Base
  belongs_to :bulk_payment
  belongs_to :pp_mp_common
end
