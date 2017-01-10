class BusinessInterface < ApplicationRecord
  belongs_to :user
  validates_presence_of :user
  validates :name, presence: true

  validates :payment_method, :payment_time, presence: true

  #'AUTOMATIC' means we leave payment info with the creditor and they tap it at the time they fill our order
  def self.payment_methods
    {PAYPAL: 0, CASH: 1, PLASTIC: 2, CHECK: 3, AUTOMATIC: 4}
  end

  #'VARIOUS' was originally intended for method AUTOMATIC
  def self.payment_times
    {ATORDER: 0, ONDELIVERY: 1, AFTERDELIVERY: 2, VARIOUS: 3}
  end

  validates :payment_method, inclusion: BusinessInterface.payment_methods.values
  validates :payment_time, inclusion: BusinessInterface.payment_times.values

  def payment_method?(method_key)
    return payment_method == BusinessInterface.payment_methods[method_key]
  end

  def payment_time?(time_key)
    return payment_time == BusinessInterface.payment_times[time_key]
  end

  def friendly_payment_description
    return "#{friendly_payment_method} #{friendly_payment_time}"
  end

  def friendly_payment_method
    
    case payment_method
      when BusinessInterface.payment_methods[:PAYPAL]
        friendly_payment_method = "Paypal"
      when BusinessInterface.payment_methods[:CASH]
        friendly_payment_method = "Cash"
      when BusinessInterface.payment_methods[:PLASTIC]
        friendly_payment_method = "Plastic"
      when BusinessInterface.payment_methods[:CHECK]
        friendly_payment_method = "Check"
      when BusinessInterface.payment_methods[:AUTOMATIC]
        friendly_payment_method = "Automatic"
      else
        friendly_payment_method = "Unknown"
    end

    return friendly_payment_method

  end

  def friendly_payment_time
    
    case payment_time
      when BusinessInterface.payment_times[:ATORDER]
        friendly_payment_method = "at order"
      when BusinessInterface.payment_times[:ONDELIVERY]
        friendly_payment_method = "on delivery"
      when BusinessInterface.payment_times[:AFTERDELIVERY]
        friendly_payment_method = "after delivery"
      when BusinessInterface.payment_times[:VARIOUS]
        friendly_payment_method = "various"
      else
        friendly_payment_method = "Unknown"
    end

    return friendly_payment_method

  end

#HOW TO USE
#  consider Marty. he's going to have one user for Helen the Hen and another for Baron Farms. but payment for both need to go to marty.davis@whatever.com.
#  HtH and BF are both PRODUCER user accounts. HtH is also a distributor for BF. HtH must then have a BusinessInterface and BF must have HtH as its creditor. That is
#  BF's distributor_id must point at the HtH account

#  name: put the name of the salutation that you want on email correspondance. For example, "Select Gourmet Foods". this will show up in order emails and payment receipt
#  order_email: if order_email is non null specify the address you want order emails routed to here. else set to nil
#  order_instructions: if order_email is non null specify any special manual order submission instructions here. these will be included in the order emailed to 'david@fc.com'. if !order_email, set to nil
#  paypal_email: same concept as for order_email. paypal payment will get sent to this address. also, our payment invoice well get sent to this address.
#  payment_instructions: same concept as for order_email

end