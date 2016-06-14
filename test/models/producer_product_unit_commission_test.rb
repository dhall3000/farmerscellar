require 'test_helper'

class ProducerProductUnitCommissionTest < ActiveSupport::TestCase

  def setup
    @producer = users(:f1)
    @product = products(:apples)
    @unit = units(:pound)
  end

  test "should not create without producer set" do
    ppuc = ProducerProductUnitCommission.new(product_id: @product.id, unit_id: @unit.id, commission: 0.05);
    assert_not ppuc.valid?
    assert_not ppuc.save    
  end

  test "should not create without product set" do
    ppuc = ProducerProductUnitCommission.new(user_id: @producer.id, unit_id: @unit.id, commission: 0.05);
    assert_not ppuc.valid?
    assert_not ppuc.save    
  end

  test "should not create without unit set" do
    ppuc = ProducerProductUnitCommission.new(user_id: @producer.id, product_id: @product.id, commission: 0.05);
    assert_not ppuc.valid?
    assert_not ppuc.save    
  end

  test "should not create without commission set" do
    ppuc = ProducerProductUnitCommission.new(user_id: @producer.id, product_id: @product.id, unit_id: @unit.id);
    assert_not ppuc.valid?
    assert_not ppuc.save    
  end

  test "should create" do
    ppuc = ProducerProductUnitCommission.new(user_id: @producer.id, product_id: @product.id, unit_id: @unit.id, commission: 0.05);
    assert ppuc.valid?
    assert ppuc.save    
  end

end
