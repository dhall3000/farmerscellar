require 'utility/rake_helper'

desc "This task is called by the Heroku scheduler add-on"

task :hourly_tasks => :environment do
  RakeHelper.do_hourly_tasks
end

task :mailer_test => :environment do

  transitioned_tote_ids = [1,7,3,4]

  subject = "commit_totes job summary report"
  body = get_commit_totes_email_body(transitioned_tote_ids)

  AdminNotificationMailer.general_message(subject, body).deliver_now
  
end