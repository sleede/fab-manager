web:    bundle exec rails server puma -p $PORT
worker: bundle exec sidekiq -C ./config/sidekiq.yml
wp-client: bin/webpacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=yes bin/webpacker --watch
