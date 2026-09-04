if Rails.env.production? || Rails.env.staging?
  # Without an explicit url: here, Sidekiq still resolves REDIS_URL on its
  # own (Sidekiq::RedisConnection#create falls back to it internally) - but
  # silently, with nothing in this file showing that's where it comes from.
  # ENV.fetch (no default) so a missing REDIS_URL fails loudly at boot,
  # not as a confusing connection-refused deep inside a background job.
  redis_config = { url: ENV.fetch('REDIS_URL'), ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
