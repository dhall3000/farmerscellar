class BpPpMpError < ApplicationRecord
  belongs_to :bulk_payment
  belongs_to :pp_mp_error
end
