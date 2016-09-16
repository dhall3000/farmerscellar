class Setting < ApplicationRecord
  belongs_to :user
  validates_presence_of :user

  #2016-09-16 this model is probably going to become a nightmarish mess if FC grows/succeeds. in that case it's a mess for another day. in the
  #meantime i'm just going to plunk all 'settings' here, with the user is producer, distributor, customer, admin etc
  #until this gets cleaned up let's just try to document here what each model column is for so there's no confusion.
  #by the way, i fiddled around with Single Table Inheritance and it smelled like a disaster so i'm abandoning that until such a time
  #as FC can hire better devs than me to clean this up

  #ATTRIBUTE conditional_payment
  #when payment to producers was first implemented it was with an ebay-esque business model in mind. if a person posts a bicycle for sale on ebay
  #and ships his bike to someone the seller doesn't get paid and neither does ebay. everybody loses. this is what i had in mind for FC. so a 
  #PaymentPayable object would only get created if/after a purchasereceivable got successfully paid on. however i'm thinking it might be hard to
  #build the business with this strategy in mind. farmer's seem to have a hard time comprehending anything other than a standard wholesale/retail
  #relationship where the retailer takes posession of the product and what they do with it or how they collect on it thereafter is none of the
  #producer's business. so, to get the business up off the ground i'm going to make the default be that if FC is unable to collect funds we just
  #eat the loss ourselves. so conditional_payment will be set to 'false' by default so a payment payable object should get created unconditionally
  #once a tote item gets FILLED

end