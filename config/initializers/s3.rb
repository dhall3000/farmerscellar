CarrierWave.configure do |config|  

  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['S3_KEY'],
    aws_secret_access_key: ENV['S3_SECRET'],
    region: 'us-west-2'
  }
  
  if Rails.env.test? || Rails.env.development?
    config.storage           = :file
    config.enable_processing = false
  elsif Rails.env.production?
    config.storage = :fog
    config.cache_dir        = "#{Rails.root}/public/tmp"
  end
  
  config.fog_directory    = ENV['S3_BUCKET_NAME']

end