require 'test_helper'

class EmailTest < ActiveSupport::TestCase

  test "email should have subject" do
    email = Email.new(body: "hello body")
    assert_not email.valid?    
  end

  test "email should have body" do
    email = Email.new(subject: "hello subject")
    assert_not email.valid?    
  end

  test "email should have posting" do
    email = Email.new(subject: "hello subject", body: "hello body")
    assert_not email.valid?    
  end

  test "email should be valid" do
    email = Email.new(subject: "hello subject", body: "hello body")
    posting = create_posting
    email.postings << posting
    assert email.valid?    
    assert email.save
  end

end