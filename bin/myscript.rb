puts "hello"

def avg_customers_per_week(start_date, end_date)

  if start >= end_date
    puts "start_date must be < end_date"
    return
  end

  total_num_users = 0
  num_weeks = 0

  while start_date < end_date
    next_start = start_date + 7.days
    num_users_for_week = User.joins(tote_items: :posting).where(tote_items: {state: ToteItem.states[:FILLED]}).where("postings.delivery_date > ? and postings.delivery_date <= ?", start_date, next_start).distinct.count
    start_date = next_start
    num_weeks += 1
    total_num_users += num_users_for_week

    puts "week #{num_weeks.to_s}"
    puts "number users: #{num_users_for_week.to_s}"
    puts "-------"

  end

  puts "Average Users per Week: #{(total_num_users.to_f / num_weeks.to_f).round(1).to_s}"

end

now = Time.zone.now
start = now - 90.days
avg_customers_per_week(start, now)