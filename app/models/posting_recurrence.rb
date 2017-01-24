class PostingRecurrence < ApplicationRecord

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
  		["Monthly", 5]
  	]
  end

  validates :frequency, presence: true
  validates :frequency, inclusion: [
    PostingRecurrence.frequency[0][1],
    PostingRecurrence.frequency[1][1],
    PostingRecurrence.frequency[2][1],
    PostingRecurrence.frequency[3][1],
    PostingRecurrence.frequency[4][1],
    PostingRecurrence.frequency[5][1]
  ]

  validates_presence_of :postings

  def friendly_frequency
    return PostingRecurrence.frequency[frequency][0]
  end

  #constraints:
  #can't be sunday or monday
  #must be in the future relative to current_posting
  #order_cutoff must be modified independantly
  #
  #here's how you should use this: say a farmer tells you he wants to switch from wednesday delivery to thursday.
  #and he wants his first thursday delivery to be on september 7th. wait until after the system generates the
  #september 6th posting and then, before it generates the september 13th posting, call this method.
  #NOTE: this is a stupid method. i'm way overthinking this. if/when we need to change a posting recurrence wday
  #just wait until a posting is generated with an incorrect wday (i.e. the first posting that's a wednesday (old wday)
  #that should be the new wday (i.e. thursday)) and make it be the new wday. however you if you're changing, say, from
  #a delivery day of friday to a delivery day of tuesday and you do this by backing up the delivery day in the current
  #week (rather than scooting it forward to the tuesday of the following week) you need to not make the new delivery date
  #prior to the order cutoff. saving will fail. if this would be the case you must first back up the order cutoff and while
  #doing that need to make sure you don't back the order cutoff before the current time (i.e. Time.zone.now)
  def change_delivery_day?(new_wday)

    #we must have at least one posting    
    if current_posting.nil?
      return false
    end

    #we don't take deliveries on sunday or monday
    if new_wday == 0 || new_wday == 1
      return false
    end

    current_wday = current_posting.delivery_date.wday
    new_delivery_date = current_posting.delivery_date
    
    if new_wday == current_wday
      #this is not a change
      return false
    else
      while new_delivery_date.wday != new_wday
        if new_wday > current_wday
          new_delivery_date += 1.day
        else
          new_delivery_date -= 1.day
        end        
      end
    end
    
    if new_delivery_date < Time.zone.now.midnight
      #we can't set the new delivery date to before today
      #if we got here it means the newwday is less than the current wday
      #but backing up to get to the new wday made us go behind today (i.e. Time.zone.now)
      #so we need to go back to the current wday and then go forward from there
      new_delivery_date = current_posting.delivery_date
      while new_delivery_date.wday != new_wday
        new_delivery_date += 1.day
      end
    end    

    return current_posting.update(delivery_date: new_delivery_date)

  end

  def turn_off
    update(on: false)
    subscriptions.each do |subscription|
      subscription.turn_off
    end    
  end

  def subscription_description(subscription_frequency)
    subscription_create_options    
    return @descriptions[subscription_frequency]
  end

  def subscription_create_options

    options = [{subscription_frequency: 0, text: @@just_once, next_delivery_date: current_posting.delivery_date}]
    @descriptions = [@@just_once]

    case frequency
    when 0 #just once posting frequency      
    when 1 #weekly posting frequency

      subscription_frequency = 1
      options << {subscription_frequency: subscription_frequency, text: @@every_week, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_week

      subscription_frequency = 2
      options << {subscription_frequency: subscription_frequency, text: @@every_2_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_2_weeks

      subscription_frequency = 3
      options << {subscription_frequency: subscription_frequency, text: @@every_3_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_3_weeks

      subscription_frequency = 4
      options << {subscription_frequency: subscription_frequency, text: @@every_4_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_4_weeks
      
    when 2 #every 2 weeks posting frequency

      subscription_frequency = 1
      options << {subscription_frequency: subscription_frequency, text: @@every_2_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_2_weeks

      subscription_frequency = 2
      options << {subscription_frequency: subscription_frequency, text: @@every_4_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_4_weeks

      subscription_frequency = 3
      options << {subscription_frequency: subscription_frequency, text: @@every_6_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_6_weeks

      subscription_frequency = 4
      options << {subscription_frequency: subscription_frequency, text: @@every_8_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_8_weeks

    when 3 #every 3 weeks posting frequency

      subscription_frequency = 1
      options << {subscription_frequency: subscription_frequency, text: @@every_3_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_3_weeks

      subscription_frequency = 2
      options << {subscription_frequency: subscription_frequency, text: @@every_6_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_6_weeks
      
    when 4 #every 4 weeks posting frequency

      subscription_frequency = 1
      options << {subscription_frequency: subscription_frequency, text: @@every_4_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_4_weeks

      subscription_frequency = 2
      options << {subscription_frequency: subscription_frequency, text: @@every_8_weeks, next_delivery_date: current_posting.delivery_date}
      @descriptions << @@every_8_weeks
      
    when 5 #monthly posting frequency

      subscription_frequency = 1
      options << {subscription_frequency: subscription_frequency, text: get_text_for(current_posting.delivery_date, 5, 1), next_delivery_date: current_posting.delivery_date}
      @descriptions << get_text_for(current_posting.delivery_date, 5, 1)

      subscription_frequency = 2
      options << {subscription_frequency: subscription_frequency, text: get_text_for(current_posting.delivery_date, 5, 2), next_delivery_date: current_posting.delivery_date}
      @descriptions << get_text_for(current_posting.delivery_date, 5, 2)

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
      week_number = "Last"
    end

    other = ""

    if subscription_frequency == 2      
      other = " 2nd"
    end

    return "#{week_number} #{date.strftime("%A")} every#{other} month"

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

    old_post = postings.order("postings.id").last
    now = Time.zone.now

    #if we're not between the most recently posted post's commit zone and delivery date, just quit
    if now < old_post.order_cutoff || now > old_post.delivery_date
      return
    end

    #copy old_post
    new_post = old_post.dup       
    #set new_post delivery_date
    #NOTE: the + 10.weeks is kinda arbitrary. might need to be revisited later. just want to keep moving for now so don't
    #want to spend brain cycles doing anything 'smart' here.
    new_post.delivery_date = get_delivery_dates_for(old_post.delivery_date, old_post.delivery_date + (10 * 7).days)[0]

    #set new_post commitment zone start
    commitment_zone_window = old_post.delivery_date - old_post.order_cutoff
    new_post.order_cutoff = new_post.delivery_date - commitment_zone_window
    new_post.live = true
    #if there doesn't already exist a post with these parameters
    reload
    if postings.where(delivery_date: new_post.delivery_date).count == 0
      if new_post.save

        #associate the photos from the old posting with this new posting
        old_post.uploads.each do |upload|
          new_post.uploads << upload
        end

        new_post.save
        
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

  #this should return all dates
  #exclude start_date
  #include end_date
  def get_delivery_dates_for(start_date, end_date)
    
    delivery_dates = []

    if end_date < start_date
      return delivery_dates
    end

    if !current_posting || current_posting.delivery_date.nil?
      return delivery_dates
    end

    #start at current_posting and compute forward
    if posting = get_first_posting_after(start_date)
      delivery_date = posting.delivery_date
    else
      delivery_date = current_posting.delivery_date
    end

    #quit when computed date is beyond end_date
    while delivery_date <= end_date

      #for each computed date include it if it falls within the parameterized date range
      if delivery_date > start_date
        delivery_dates << delivery_date
      end

      #compute next scheduled delivery date
      case frequency
      when 1..4
        delivery_date = delivery_date + (frequency * 7).days
      when 5        
        week_number = get_week_number(delivery_date)
        if week_number < 4
          #handle the 1st, 2nd or 3rd week_of_day of the month
          delivery_date = get_nth_weekday_of_next_month(delivery_date, week_number)
        else
          #we're doing the last Xday of the month
          #handle the last week_of_day of the month
          delivery_date = get_last_weekday_occurence_of_next_month(delivery_date)
        end               
      end   

    end

    return delivery_dates

  end

  def get_first_posting_after(date)
    return postings.where("delivery_date > ?", date).order("delivery_date").first
  end

  def current_posting

    if postings == nil || postings.count < 1
      return nil
    end

    return postings.order(:delivery_date).last

  end

  private

    def get_last_weekday_occurence_of_next_month(reference_date)

      next_month = get_first_day_of_next_month(reference_date)
      next_month2 = get_first_day_of_next_month(next_month)

      last_day_of_next_month = next_month2 - 1.day
      last_weekday_occurence_of_next_month = last_day_of_next_month

      while last_weekday_occurence_of_next_month.wday != reference_date.wday
        last_weekday_occurence_of_next_month = last_weekday_occurence_of_next_month - 1.day
      end

      return last_weekday_occurence_of_next_month

    end

    def get_nth_weekday_of_next_month(reference_date, week_num)

      if week_num < 1
        return nil
      end

      if week_num < 4

        first_day_of_next_month = get_first_day_of_next_month(reference_date)

        first_occurence_of_proper_day_of_week_of_next_month = first_day_of_next_month

        while first_occurence_of_proper_day_of_week_of_next_month.wday != reference_date.wday
          first_occurence_of_proper_day_of_week_of_next_month = first_occurence_of_proper_day_of_week_of_next_month + 1.day
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
        first_day_of_next_month = first_day_of_next_month + 1.day
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