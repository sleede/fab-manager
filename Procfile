web:    bundle exec rails server puma -p $PORT
worker: bundle exec sidekiq -C ./config/sidekiq.yml
mail:   mailcatcher --foreground --http-ip=0.0.0.0
