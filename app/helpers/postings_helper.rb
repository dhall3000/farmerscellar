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

    #the reason for this .dup is because the postings relation has been ordered upstream of here and we won't want to disturb it
    #for viewing. i tried using postings.minimum(:delivery_date) but somehow will_paginate doesn't like this. see my post here:
    #http://stackoverflow.com/questions/43527078/why-does-will-paginate-maximum-return-nil
    #so my hack here so that i can proceed is to dup the relation, order it how i need to, get .first and .last and proceed all
    #while leaving postings relation undisturbed
    postings_dup = postings.dup

    first = postings_dup.order(:delivery_date).first.delivery_date
    last  = postings_dup.order(:delivery_date).last.delivery_date

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