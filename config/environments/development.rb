Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

#----------------------------------------custom below----------------------------------------

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :test
  host = 'localhost:3000'
  config.action_mailer.default_url_options = { host: host }

  ENV['PAYPALCREDENTIALS'] = "{\"USER\" => \"davideltonhall-facilitator_api1.gmail.com\", \"PWD\" => \"2U4THLGZVCG6BSHH\",\"SIGNATURE\" => \"An5ns1Kso7MWUdW4ErQKJJJ4qi4-A-.uIGKotw7d0j4apBMju1cKS2pZ\"}"
  ENV['FOODCLEAROUTDAYTIME'] = "{wday: 1, hour: 20}"
  ENV['FOODCLEAROUTWARNINGDAYTIME'] = "{wday: 1, hour: 6}"  
  ENV['S3_KEY'] = ""
  ENV['S3_SECRET'] = ""
  ENV['S3_BUCKET_NAME'] = ""
  
  config.after_initialize do
    ::HEADERICONTITLE = "FCIconBare32"
    ::LANDINGSPLASHTITLE = "LandingSplash"
    ::NOPRODUCTIMAGETITLE = "NoProductImage"
    ::PAYPALCREDENTIALS = eval(ENV['PAYPALCREDENTIALS'])
    ::FOODCLEAROUTDAYTIME = eval(ENV['FOODCLEAROUTDAYTIME'])
    ::FOODCLEAROUTWARNINGDAYTIME = eval(ENV['FOODCLEAROUTWARNINGDAYTIME'])
    #so query against this like so: if Time.zone.today.wday == STARTOFWEEK
    ::STARTOFWEEK = FOODCLEAROUTDAYTIME[:wday]
    ::PRODUCERDEFAULTPASSWORD = "defaultproducerpassword"

    ActiveMerchant::Billing::Base.mode = :test    
    ::GATEWAY = ActiveMerchant::Billing::PaypalExpressGateway.new(
      login: PAYPALCREDENTIALS["USER"],
      password: PAYPALCREDENTIALS["PWD"],
      signature: PAYPALCREDENTIALS["SIGNATURE"]
      )

    ::PAYPALMASSPAYENDPOINT = "https://api-3t.sandbox.paypal.com"
    
    ::USEGATEWAY = false

    #this is intended to function a bit like a database so that i don't have to create new models just to fiddle with features like paypal reference transactions
    ::PAYPALDATASTORE = {}

  end

end