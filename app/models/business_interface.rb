class BusinessInterface < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user

#HOW TO USE
#  consider Marty. he's going to have one user for Helen the Hen and another for Baron Farms. but payment for both need to go to marty.davis@whatever.com.
#  so while HtH and BF are PRODUCER user accounts, there will be a third DISTRIBUTOR user account which will have a businessinterface whose .paypal_email will be marty.davis@whatever.com. so we need to test for this.

#  name: put the name of the salutation that you want on email correspondance. For example, "Select Gourmet Foods". this will show up in order emails and payment receipt
#  order_email_accepted: if this is true, order will get sent to 'order_email'. if this is false emails are hardcoded to 'david@farmerscellar.com' and the greeting also used that email address
#  order_email: if order_email_accepted specify the address you want order emails routed to here. else set to nil
#  order_instructions: if order_email_accepted specify any special manual order submission instructions here. these will be included in the order emailed to 'david@fc.com'. if !order_email_accepted, set to nil
#  paypal_accepted: same concept as for order_email_accepted
#  paypal_email: same concept as for order_email_accepted. paypal payment will get sent to this address. also, our payment invoice well get sent to this address.
#  payment_instructions: same concept as for order_email_accepted

  def distributor?
    return user.account_type_is?(:DISTRIBUTOR)
  end
end
