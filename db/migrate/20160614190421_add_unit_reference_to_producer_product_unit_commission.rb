class AddUnitReferenceToProducerProductUnitCommission < ActiveRecord::Migration
  def change

    add_reference :producer_product_unit_commissions, :unit, index: true
    add_foreign_key :producer_product_unit_commissions, :units

    Posting.all.each do |posting|

      producer = posting.user
      product = posting.product
      unit = posting.unit

      rows = ProducerProductUnitCommission.where(user: producer, product: product)

      rows.each do |row|
        row.update(unit_id: unit.id)        
      end

    end

    change_column :producer_product_unit_commissions, :unit_id, :integer, null: false

  end
end
