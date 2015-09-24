require 'test_helper'

class AdminNotificationMailerTest < ActionMailer::TestCase
  test "general_message" do
    mail = AdminNotificationMailer.general_message("my subject", "my body")
    assert_equal "my subject", mail.subject
    assert_equal ["david@farmerscellar.com"], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match "Hello", mail.body.encoded
  end

end
