# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# allow use rails helpers in angular templates
Rails.application.config.assets.configure do |env|
  env.context_class.class_eval do
    include ActionView::Helpers
    include Rails.application.routes.url_helpers
  end
end

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

Rails.application.config.assets.precompile += %w[
  fontawesome-webfont.eot
  fontawesome-webfont.woff
  fontawesome-webfont.svg
  fontawesome-webfont.ttf
]
Rails.application.config.assets.precompile += %w[app.printer.css]

Rails.application.config.assets.precompile += %w[
  angular-i18n/angular-locale_*.js
  moment/locale/*.js
  summernote/lang/*.js
  fullcalendar/dist/lang/*.js
]
