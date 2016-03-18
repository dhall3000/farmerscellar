require 'utility/rake_helper'

desc "This task is called by the Heroku scheduler add-on"

task :hourly_tasks => :environment do
  RakeHelper.do_hourly_tasks
end

task :nightly_tasks => :environment do
  RakeHelper.do_nightly_tasks
end

task :week_end_tasks => :environment do
  RakeHelper.do_week_end_tasks
end

task :mailer_test => :environment do
  
  subject = "my mailer_test subject"
  body = "my mailer_test body"

  AdminNotificationMailer.general_message(subject, body).deliver_now
  
end