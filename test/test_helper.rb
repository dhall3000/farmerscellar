ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def assert_appropriate_email(mail, to, subject, body)
    assert_equal subject, mail.subject
    assert_equal [to], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match body, mail.body.encoded
  end

  # Add more helper methods to be used by all tests here...
  def is_logged_in?
  	!session[:user_id].nil?
  end

  # Logs in a test user.
  def log_in_as(user, options = {})
    password    = options[:password]    || 'dogdog'
    remember_me = options[:remember_me] || '1'
    if integration_test?
      post login_path, session: { email:       user.email,
                                  password:    password,
                                  remember_me: remember_me }
    else
      session[:user_id] = user.id
    end
  end

  def get_access_code    
    @a1 = users(:a1)
    log_in_as(@a1)
    post access_codes_path, access_code: {notes: "empty notes"}
    code = assigns(:code)

    return code

  end

  def get_access_for(user)
    code = get_access_code
    log_in_as(user)
    patch user_path(user), user: { access_code: code }
  end

  def get_error_messages(active_record_object)

    messages = ""

    if active_record_object.nil? || active_record_object.errors.count < 1      
      messages = "There are no activerecord errors"
      return messages
    end

    active_record_object.errors.full_messages.each do |message|
      messages += message + ", "
    end

    return messages

  end

  private

    # Returns true inside an integration test.
    def integration_test?
      defined?(post_via_redirect)
    end
  
end
