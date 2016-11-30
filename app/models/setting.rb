class Setting < ApplicationRecord
  belongs_to :user
  validates_presence_of :user

  #2016-09-16 this model is probably going to become a nightmarish mess if FC grows/succeeds. in that case it's a mess for another day. in the
  #meantime i'm just going to plunk all 'settings' here, with the user is producer, distributor, customer, admin etc
  #until this gets cleaned up let's just try to document here what each model column is for so there's no confusion.
  #by the way, i fiddled around with Single Table Inheritance and it smelled like a disaster so i'm abandoning that until such a time
  #as FC can hire better devs than me to clean this up

end