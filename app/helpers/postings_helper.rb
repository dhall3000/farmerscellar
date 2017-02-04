module PostingsHelper

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

    while ancestor
      food_category_ancestors << ancestor
      ancestor = ancestor.parent
    end

    food_category_ancestors.reverse!

    return food_category_ancestors

  end

  def display_delivery_range_buttons?(this_weeks_postings, next_weeks_postings, future_postings)

    count = 0

    if this_weeks_postings.any?
      count += 1
    end

    if next_weeks_postings.any?
      count += 1
    end

    if future_postings.any?
      count += 1
    end

    return count > 1

  end

  def get_delivery_range_schedule_text(postings)

    if postings.nil? || !postings.any?
      return nil
    end

    first = postings.order(delivery_date: :asc).first.delivery_date
    last = postings.order(delivery_date: :asc).last.delivery_date

    if first == last
      return "Delivery scheduled #{friendly_date(first)}"
    else
      return "Deliveries scheduled #{friendly_date(first)} - #{friendly_date(last)}"
    end

  end

  def friendly_date(date)
    return "#{date.strftime("%a %b")} #{date.day.ordinalize}"
  end

end