module FoodCategoriesHelper

  #gets links and link text for page-top nav trinket
  def get_top_down_ancestors(food_category, include_self)

    food_category_ancestors = []

    if food_category.nil?
      return food_category_ancestors
    end

    if include_self
      ancestor = food_category
    else
      ancestor = food_category.parent
    end    

    while ancestor.parent
      link = {text: ancestor.name, path: Rails.application.routes.url_helpers.postings_path(food_category: ancestor.name)}
      food_category_ancestors << link
      ancestor = ancestor.parent
    end

    food_category_ancestors.reverse!

    return food_category_ancestors

  end

end