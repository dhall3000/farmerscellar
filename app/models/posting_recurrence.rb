class PostingRecurrence < ActiveRecord::Base
  has_many :postings
  has_many :subscriptions

  @@just_once = "Just once"
  @@every_week = "Every week"
  @@every_2_weeks = "Every 2 weeks"
  @@every_3_weeks = "Every 3 weeks"
  @@every_4_weeks = "Every 4 weeks"
  @@every_6_weeks = "Every 6 weeks"
  @@every_8_weeks = "Every 8 weeks"

  def self.frequency  	
  	[
  		[@@just_once, 0],
  		[@@every_week, 1],
  		[@@every_2_weeks, 2],
  		[@@every_3_weeks, 3],
  		[@@every_4_weeks, 4],
  		["Monthly", 5],
      ["Three weeks on, one week off", 6]
  	]
  end

  validates :frequency, presence: true
  validates :frequency, inclusion: [
    PostingRecurrence.frequency[0][1],
    PostingRecurrence.frequency[1][1],
    PostingRecurrence.frequency[2][1],
    PostingRecurrence.frequency[3][1],
    PostingRecurrence.frequency[4][1],
    PostingRecurrence.frequency[5][1],
    PostingRecurrence.frequency[6][1]
  ]

  validates_presence_of :postings

  def subscribable?
    return on == true
  end

  def subscription_options

    options = [{subscription_frequency: 0, text: @@just_once, next_delivery_date: next_delivery_date(0)}]

    case frequency
    when 0 #just once posting frequency      
    when 1 #weekly posting frequency
      options << {subscription_frequency: 1, text: @@every_week, next_delivery_date: next_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_2_weeks, next_delivery_date: next_delivery_date(2)}
      options << {subscription_frequency: 3, text: @@every_3_weeks, next_delivery_date: next_delivery_date(3)}
      options << {subscription_frequency: 4, text: @@every_4_weeks, next_delivery_date: next_delivery_date(4)}
    when 2 #every 2 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_2_weeks, next_delivery_date: next_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_4_weeks, next_delivery_date: next_delivery_date(2)}
      options << {subscription_frequency: 3, text: @@every_6_weeks, next_delivery_date: next_delivery_date(3)}
      options << {subscription_frequency: 3, text: @@every_8_weeks, next_delivery_date: next_delivery_date(4)}
    when 3 #every 3 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_3_weeks, next_delivery_date: next_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_6_weeks, next_delivery_date: next_delivery_date(2)}
    when 4 #every 4 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_4_weeks, next_delivery_date: next_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_8_weeks, next_delivery_date: next_delivery_date(2)}
    when 5 #monthly posting frequency
      #TODO: the :text label below needs to say something like "The last Tuesday of every month" or "The 2nd Tuesday of every month"
      options << {subscription_frequency: 1, text: "Every month", next_delivery_date: next_delivery_date(1)}
      #TODO: the :text label below needs to say something like "Every 2 months on the last Tuesday"
      options << {subscription_frequency: 2, text: "Every 2 months", next_delivery_date: next_delivery_date(2)}
    when 6 #3 weeks on, 1 week off posting frequency
      options << {subscription_frequency: 1, text: "3 weeks on, 1 week off", next_delivery_date: next_delivery_date(1)}
      #TODO: need to implement the subscription schedules every_2_weeks and every_4_weeks
      #PostingRecurrence.frequency[6][1] => [[@@just_once, 0], ["3 weeks on, 1 week off", 1], [@@every_2_weeks, 2], [@@every_4_weeks, 3]]
      #There are more notes in trello regarding this. you should be able to find the trello card by using the above line of code options <<
      #to search in Trello
    end    

    return options

  end

  def recur

    #if there is no recurrence, just quit
    if frequency < 1
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
    if frequency >= 1 && frequency <= 4
      new_post.delivery_date = old_post.delivery_date + frequency.weeks
    elsif frequency == 5
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

    elsif frequency == 6
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

    if frequency == 6

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

  #this method envisions a day when we have tons of posting frequency and subscription frequency options. at that time we might have to
  #do some fancy calculation to determine when the next delivery date is. for example, Marty (Helen the Hen) delivery 3 weeks on, 1 week off.
  #this theoretically could support an "every delivery" subscription as well as "every other week" and "every 4 weeks". however, to implement
  #the latter two subscription frequencies we'd have to do special computation to figure out when the next delivery schedule is because there
  #are situations where it's not the next delivery but rather the delivery after next since those two subscription frequencies can only be
  #started on week #1 and #3 of his 4 week cycle.
  #for now we're not going to implement subscription frequencies that require special treatment because they're not the lowest hanging fruit.
  #so the thinking with this method is to basically stub it out and call in to it so that down the road if/when we want to implement the things
  #discussed in this comment we just need to throw a few codes in the case statements below and we should be off to the races.
  def next_delivery_date(subscription_frequency)

    next_delivery_date = postings.last.delivery_date

    case frequency
    when 6 #marty's "3 on, 1 off" posting/delivery schedule
      case subscription_frequency      
      when 2 #every 2 weeks
        #NOT IMPLEMENTED AS OF NOW: 2016-03-05
        #at implementation time, put code here that figures out when the start date is
      when 3 #every 4 weeks
        #NOT IMPLEMENTED AS OF NOW: 2016-03-05
        #at implementation time, put code here that figures out when the start date is
      end    
    end

    return next_delivery_date

  end

  def current_posting

    if postings == nil || postings.count < 1
      return nil
    end

    return postings.last

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