class ProducerProductUnitCommission < ApplicationRecord
  belongs_to :product
  belongs_to :user
  belongs_to :unit

  validates :user_id, :product_id, :unit_id, :commission, presence: true
  validates :commission, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  #these are somewhat hack'ish. their purpose is to speed workflow when taking on a new producer.
  #when taking on a new producer you now have to post all their products. this means you're going
  #to be setting a bunch of these PPUC objects. the usual way to do this is by providing user,
  #product, unit, retail and producer_net prices. if we have 10 products to post there will be tons
  #of redundant mouse clicking. these attributes partially ease that burden. for now (2016-12-21).
  attr_accessor :retail, :producer_net

  def self.get_current_commission_factor(producer, product, unit)

    commission_factors = ProducerProductUnitCommission.where(user: producer, product: product, unit: unit)

    #TODO: the following line is superfluous, as far as i can tell. however, i get a sqlliteexception without it. strange!
    #i don't think there's anything magical about calling .to_a. when creating this i was able to get things to succeed
    #as intended when i used a variety of reading methods instead of .to_a
    commission_factors.to_a

    if commission_factors.order(:created_at).last.nil?
      return 0
    else
      return commission_factors.order(:created_at).last.commission
    end    

  end

end