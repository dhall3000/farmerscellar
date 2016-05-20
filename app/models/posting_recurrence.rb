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

  def turn_off
    update(on: false)
    subscriptions.each do |subscription|
      subscription.turn_off
    end    
  end

  def subscribable?
    return on == true
  end

  def subscription_options

    options = [{subscription_frequency: 0, text: @@just_once, next_delivery_date: get_new_subscription_start_delivery_date(0)}]

    case frequency
    when 0 #just once posting frequency      
    when 1 #weekly posting frequency
      options << {subscription_frequency: 1, text: @@every_week, next_delivery_date: get_new_subscription_start_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_2_weeks, next_delivery_date: get_new_subscription_start_delivery_date(2)}
      options << {subscription_frequency: 3, text: @@every_3_weeks, next_delivery_date: get_new_subscription_start_delivery_date(3)}
      options << {subscription_frequency: 4, text: @@every_4_weeks, next_delivery_date: get_new_subscription_start_delivery_date(4)}
    when 2 #every 2 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_2_weeks, next_delivery_date: get_new_subscription_start_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_4_weeks, next_delivery_date: get_new_subscription_start_delivery_date(2)}
      options << {subscription_frequency: 3, text: @@every_6_weeks, next_delivery_date: get_new_subscription_start_delivery_date(3)}
      options << {subscription_frequency: 4, text: @@every_8_weeks, next_delivery_date: get_new_subscription_start_delivery_date(4)}
    when 3 #every 3 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_3_weeks, next_delivery_date: get_new_subscription_start_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_6_weeks, next_delivery_date: get_new_subscription_start_delivery_date(2)}
    when 4 #every 4 weeks posting frequency
      options << {subscription_frequency: 1, text: @@every_4_weeks, next_delivery_date: get_new_subscription_start_delivery_date(1)}
      options << {subscription_frequency: 2, text: @@every_8_weeks, next_delivery_date: get_new_subscription_start_delivery_date(2)}
    when 5 #monthly posting frequency
      options << {subscription_frequency: 1, text: get_text_for(get_new_subscription_start_delivery_date(1), 5, 1), next_delivery_date: get_new_subscription_start_delivery_date(1)}
      options << {subscription_frequency: 2, text: get_text_for(get_new_subscription_start_delivery_date(2), 5, 2), next_delivery_date: get_new_subscription_start_delivery_date(2)}
    when 6 #3 weeks on, 1 week off posting frequency
      options << {subscription_frequency: 1, text: "3 weeks on, 1 week off", next_delivery_date: get_new_subscription_start_delivery_date(1)}
      #options << {subscription_frequency: 2, text: "Every other week", next_delivery_date: get_new_subscription_start_delivery_date(2)}
      options << {subscription_frequency: 3, text: "Every 4 weeks", next_delivery_date: get_new_subscription_start_delivery_date(3)}
    end    

    return options

  end

  def get_text_for(date, posting_recurrence_frequency, subscription_frequency)

    if posting_recurrence_frequency != 5
      return
    end

    if ![1, 2].include?(subscription_frequency)
      return
    end

    week_number = get_week_number(date)

    if week_number < 4
      week_number = week_number.ordinalize
    else
      week_number = "last"
    end

    other = ""

    if subscription_frequency == 2      
      other = " other"
    end

    return "Every#{other} #{week_number} #{date.strftime("%A")} of the month"

  end

  def subscription_description(subscription_frequency)
    options = subscription_options
    return options[subscription_frequency][:text]
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
    reload
    if postings.where(delivery_date: new_post.delivery_date).count == 0
      if new_post.save
        
        #add to posting_recurrence.postings
        postings << new_post
        save

        #kick the subscriptions
        subscriptions.each do |subscription|
          subscription.generate_next_tote_item
        end

        save

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

  def current_posting

    if postings == nil || postings.count < 1
      return nil
    end

    return postings.order(:delivery_date).last

  end

  #NOTE: the way to understand this method is from the front end perspective. when user is going to add a new subscription to their 
  #tote we want to display some help text. most of the time (for all posting frequencies < 5) the "next delivery date" is going to
  #simply be the date of the .last posting. it will only vary from that (in this front-end usage scenario) if a person is adding
  #a subscription to a funky delivery schedule (e.g. Marty / Helen the Hen's 3 weeks on, one week off schedule) and specifying
  #every other week. actually, i think subscribing to a every-other-week of Helen the Hen is the ONLY (for now) case in which
  #next delivery date would be other than postings.last.delivery_date. even for a every-4-weeks subscription of Helen the Hen the
  #next delivery date would be postings.last.delivery_date.

  #this method envisions a day when we have tons of posting frequency and subscription frequency options. at that time we might have to
  #do some fancy calculation to determine when the next delivery date is. for example, Marty (Helen the Hen) delivery 3 weeks on, 1 week off.
  #this theoretically could support an "every delivery" subscription as well as "every other week" and "every 4 weeks". however, to implement
  #the latter two subscription frequencies we'd have to do special computation to figure out when the next delivery schedule is because there
  #are situations where it's not the next delivery but rather the delivery after next since those two subscription frequencies can only be
  #started on week #1 and #3 of his 4 week cycle.
  #for now we're not going to implement subscription frequencies that require special treatment because they're not the lowest hanging fruit.
  #so the thinking with this method is to basically stub it out and call in to it so that down the road if/when we want to implement the things
  #discussed in this comment we just need to throw a few codes in the case statements below and we should be off to the races.
  def get_new_subscription_start_delivery_date(subscription_frequency)

    new_subscription_start_delivery_date = current_posting.delivery_date

    if frequency == 6 && subscription_frequency == 2

      #this is the case where customer wants "every other week" subscription to Marty / Helen the Hen's 3 on, 1 off schedule
      one_week_of_seconds = 7 * 24 * 60 * 60
      week_num = 1
      i = postings.count - 1
      
      while i > 0
      
        gap = postings[i].delivery_date - postings[i - 1].delivery_date
      
        if gap == one_week_of_seconds
          week_num += 1
        else
          i = 0
        end
        i -= 1

      end

      if week_num == 2
        new_subscription_start_delivery_date = get_next_delivery_dates(1, current_posting.delivery_date)[0]
      end

    end

    return new_subscription_start_delivery_date

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