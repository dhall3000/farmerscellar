class ChangeUnitColumnInProducerProductUnitCommissions < ActiveRecord::Migration
  def change

    pound = Unit.find_by(name: "Pound")

    ProducerProductUnitCommission.all.each do |ppuc|

      if ppuc.unit_id.nil?
        ppuc.update(unit_id: pound.id)
      end

    end

    change_column :producer_product_unit_commissions, :unit_id, :integer, null: false

  end
end
