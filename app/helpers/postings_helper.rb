module PostingsHelper

  def display_delivery_range_buttons?(this_weeks_postings, next_weeks_postings, future_postings)

    count = 0

    if this_weeks_postings && this_weeks_postings.any?
      count += 1
    end

    if next_weeks_postings && next_weeks_postings.any?
      count += 1
    end

    if future_postings && future_postings.any?
      count += 1
    end

    return count > 1

  end

  def get_delivery_range_schedule_text(postings)

    if postings.nil? || !postings.any?
      return nil
    end

    first = postings.minimum(:delivery_date)
    last  = postings.maximum(:delivery_date)

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