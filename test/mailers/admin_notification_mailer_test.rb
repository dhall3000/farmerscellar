require 'test_helper'

class AdminNotificationMailerTest < ActionMailer::TestCase
  test "commit_totes" do
    mail = AdminNotificationMailer.commit_totes
    assert_equal "Commit totes", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
