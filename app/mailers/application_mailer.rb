class ApplicationMailer < ActionMailer::Base
  default from: "Farmer's Cellar <david@farmerscellar.com>", bcc: "david@farmerscellar.com"
  layout 'mailer'
end