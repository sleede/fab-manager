# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

redis_host = ENV.fetch('REDIS_HOST', 'localhost')

Rails.application.config.session_store :redis_session_store,
                                       redis: {
                                         expire_after: 14.days,  # cookie expiration
                                         ttl: 14.days,           # Redis expiration, defaults to 'expire_after'
                                         key_prefix: 'fabmanager:session:',
                                         url: "redis://#{redis_host}:6379"
                                       },
                                       key: '_Fab-manager_session',
                                       secure: (Rails.env.production? || Rails.env.staging?) &&
                                               !Rails.application.secrets.allow_insecure_http
