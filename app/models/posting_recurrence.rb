class PostingRecurrence < ActiveRecord::Base
  has_many :postings

  def self.intervals  	
  	[
  		["No", 0],
  		["Every week", 1],
  		["Every two weeks", 2],
  		["Every three weeks", 3],
  		["Every four weeks", 4],
  		["Monthly", 5],
      ["Three weeks on, one week off", 6]
  	]
  end

  validates :interval, :on, presence: true
  validates :interval, inclusion: [
    PostingRecurrence.intervals[0][1],
    PostingRecurrence.intervals[1][1],
    PostingRecurrence.intervals[2][1],
    PostingRecurrence.intervals[3][1],
    PostingRecurrence.intervals[4][1],
    PostingRecurrence.intervals[5][1],
    PostingRecurrence.intervals[6][1]
  ]

  def recur

    #if there is no recurrence, just quit
    if interval < 1
      return
    end

    #if this recurrence is turned off, just quit
    if !on
      return
    end

    old_post = postings.last
    now = Time.zone.now

    #if we're not between the most recently posted post's commit zone and delivery date, just quit
    if now < old_post.commitment_zone_start || now > old_post.delivery_date
      return
    end

    #set old_post.live = false
    old_post.live = false

    if !old_post.save
      body_lines = []
      body_lines << "Posting id: " + old_post.id.to_s
      body_lines << "Producer: " + old_post.user.farm_name
      body_lines << "Product: " + old_post.product.name
      AdminNotificationMailer.general_message("old post couldn't be 'unlive'd'", "false body line", body_lines).delivery_now
    end

    #copy old_post
    new_post = old_post.dup       
    #set new_post delivery_date
    if interval >= 1 && interval <= 4
      new_post.delivery_date = old_post.delivery_date + interval.weeks
    elsif interval == 5
      #this is a monthly recurrence. we have to find out which weeknumber of the month the old_post is on so that we can
      #set the new_post delivery date to the same weeknumber of the following month
      week_number = get_week_number(old_post.delivery_date)

      if week_number < 4
        #handle the 1st, 2nd or 3rd week_of_day of the month
        new_post.delivery_date = get_nth_weekday_of_next_month(old_post.delivery_date, week_number)
      else
        #we're doing the last Xday of the month
        #handle the last week_of_day of the month
        new_post.delivery_date = get_last_weekday_occurence_of_next_month(old_post.delivery_date)
      end

    elsif interval == 6
      #we're doing marty's 3 weeks on, 1 week off recurrence
      new_post.delivery_date = get_next_delivery_dates(1, old_post.delivery_date)[0]
    end

    #set new_post commitment zone start
    commitment_zone_window = old_post.delivery_date - old_post.commitment_zone_start
    new_post.commitment_zone_start = new_post.delivery_date - commitment_zone_window
    new_post.live = true
    #if there doesn't already exist a post with these parameters
    if postings.where(delivery_date: new_post.delivery_date).count == 0
      if new_post.save
        #add to posting_recurrence.postings
        postings << new_post
      end
    end
    
  end

  #the 'beyond_date' param means for this method to return the number of scheduled dates that
  #are in the future ahead of 'beyond_date'
  def get_next_delivery_dates(num_future_dates, beyond_date)

    future_delivery_dates = []

    if num_future_dates < 1
      return future_delivery_dates
    end

    if interval == 6

      date = postings.first.delivery_date

      if postings.first.user_id == 70
        #HACK! this is marty from helen the hen / baron farms. their first actual delivery to us was march 29, 2016.
        #that was the date their 3 on 1 off cycle began. but i'm coding this on march 30. so i need to get the code
        #to base its cycle off of march 29 but i can't make a posting with a delivery date in the past because
        #the posting model has a excluding validation. so i'm just going to hard code in march 29 for now as the
        #date to base the beginning of the cycle on
        date = Time.zone.local(2016, 3, 29)
      end
      date_count = 1

      while future_delivery_dates.count < num_future_dates

        if date > beyond_date
          if date_count % 4 > 0
            future_delivery_dates << date
          end
        end

        date += 7.days
        date_count += 1

      end

    end

    return future_delivery_dates

  end

  private

    def get_last_weekday_occurence_of_next_month(reference_date)

      next_month = get_first_day_of_next_month(reference_date)
      next_month2 = get_first_day_of_next_month(next_month)

      last_day_of_next_month = next_month2 - 1.day
      get_last_weekday_occurence_of_next_month = last_day_of_next_month

      while get_last_weekday_occurence_of_next_month.wday != reference_date.wday
        get_last_weekday_occurence_of_next_month = get_last_weekday_occurence_of_next_month - 1.day
      end

      return get_last_weekday_occurence_of_next_month

    end

    def get_nth_weekday_of_next_month(reference_date, week_num)

      if week_num < 1
        return nil
      end

      if week_num < 4

        first_day_of_next_month = get_first_day_of_next_month(reference_date)

        first_occurence_of_proper_day_of_week_of_next_month = first_day_of_next_month

        while first_occurence_of_proper_day_of_week_of_next_month.wday != reference_date.wday
          first_occurence_of_proper_day_of_week_of_next_month = first_occurence_of_proper_day_of_week_of_next_month.next
        end

        ret = first_occurence_of_proper_day_of_week_of_next_month + ((week_num - 1) * 7).days
        nth_weekday_of_next_month = Time.zone.local(ret.year, ret.month, ret.day)

        return nth_weekday_of_next_month

      else

      end

    end

    def get_first_day_of_next_month(reference_date)

      month_num = reference_date.month
      first_day_of_next_month = reference_date

      #advance days until we get to the first of the month
      while first_day_of_next_month.month == month_num
        first_day_of_next_month = first_day_of_next_month.to_date.next
      end

      return first_day_of_next_month

    end

    def get_week_number(date)

      num_weeks_in_to_month = date.day / 7
      num_days_in_to_week = date.day % 7

      if num_days_in_to_week > 0
        return num_weeks_in_to_month + 1
      end

      return num_weeks_in_to_month

    end

    def get_weekday_count(date)

      month_num = date.month      
      count = 0

      while date.month == month_num
        count = count + 1
        date = date - 7.days
      end

      return count

    end

end