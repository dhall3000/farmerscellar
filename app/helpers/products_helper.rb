module ProductsHelper

  def get_options_for_select

    products = Product.order(:name)
    products_for_select = []

    products.each do |product|
      ancestors_string = FoodCategoriesController.helpers.get_ancestors_string(product.food_category)
      products_for_select << {id: product.id, name: "#{product.name} / #{ancestors_string}"}
    end

    return products_for_select

  end
  
end