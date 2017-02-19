Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  
  #----------------------------------------custom below----------------------------------------
  # Randomize the order test cases are executed.
  config.active_support.test_order = :random
  config.action_mailer.default_url_options = { host: 'farmerscellar.com' }  

  ENV['S3_KEY'] = ""
  ENV['S3_SECRET'] = ""
  ENV['S3_BUCKET_NAME'] = ""

  ENV['FOODCLEAROUTDAYTIME'] = "{wday: 1, hour: 20}"
  ENV['FOODCLEAROUTWARNINGDAYTIME'] = "{wday: 1, hour: 6}"    

  config.after_initialize do
    ::HEADERICONTITLE = "FCIconBare32"
    ::LANDINGSPLASHTITLE = "LandingSplash"
    ::NOPRODUCTIMAGETITLE = "NoProductImage"
    ::FOODCLEAROUTDAYTIME = eval(ENV['FOODCLEAROUTDAYTIME'])
    ::FOODCLEAROUTWARNINGDAYTIME = eval(ENV['FOODCLEAROUTWARNINGDAYTIME'])
    #so query against this like so: if Time.zone.today.wday == STARTOFWEEK
    ::STARTOFWEEK = FOODCLEAROUTDAYTIME[:wday]

    ::PAYPALCREDENTIALS =
    {
      "USER" => "davideltonhall-facilitator_api1.gmail.com",
      "PWD" => "2U4THLGZVCG6BSHH",
      "SIGNATURE" => "An5ns1Kso7MWUdW4ErQKJJJ4qi4-A-.uIGKotw7d0j4apBMju1cKS2pZ"
    }
    ::USEGATEWAY = false
  end

end