class CleanUpEmailSendTimeColumn < ActiveRecord::Migration[5.0]
  def change
    Email.all.each do |email|
      email.update(send_time: email.created_at)
    end
  end
end