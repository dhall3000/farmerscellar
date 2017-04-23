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

    while ancestor && ancestor.parent
      link = {text: ancestor.name, path: Rails.application.routes.url_helpers.postings_path(food_category: ancestor.name)}
      food_category_ancestors << link
      ancestor = ancestor.parent
    end

    food_category_ancestors.reverse!

    return food_category_ancestors

  end

  def get_top_down_ancestors_string(food_category)
    #this returns a string something like "Market - Dairy - Milk - 2%"

    parents = get_top_down_ancestors(food_category, include_self = false)
    parent_string = ""
    parents.each do |parent|
      parent_string += parent[:text] + " / "
    end

    parent_string += food_category.name

  end

  def get_options_for_select
    food_categories = FoodCategory.order(:name)
    food_categories_for_select = []
    
    food_categories.each do |fc|
      ancestors_string = get_top_down_ancestors_string(fc)
      food_categories_for_select << {id: fc.id, name: ancestors_string}
    end

    return food_categories_for_select

  end

end