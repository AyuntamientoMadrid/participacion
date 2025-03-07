source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "7.0.8.7"

gem "acts-as-taggable-on", "~> 11.0.0"
gem "acts_as_votable", "~> 0.14.0"
gem "ahoy_matey", "~> 5.2.0"
gem "airbrake", "~> 13.0.4"
gem "ancestry", "~> 4.3.3"
gem "audited", "~> 5.7.0"
gem "autoprefixer-rails", "~> 10.4.19"
gem "bing_translator", "~> 6.2.0"
gem "cancancan", "~> 3.6.1"
gem "caxlsx", "~> 4.1.0"
gem "caxlsx_rails", "~> 0.6.4"
gem "ckeditor", "~> 4.3.0"
gem "cocoon", "~> 1.2.15"
gem "daemons", "~> 1.4.1"
gem "dalli", "~> 3.2.8"
gem "delayed_job_active_record", "~> 4.1.10"
gem "devise", "~> 4.9.4"
gem "devise-security", "~> 0.18.0"
gem "exiftool_vendored", "~> 12.97.0"
gem "file_validators", "~> 3.0.0"
gem "font-awesome-sass", "~> 5.15.1" # Remember to update vendor/assets/images/fontawesome when updating this gem
gem "foundation_rails_helper", "~> 4.0.1"
gem "globalize", "~> 6.3.0"
gem "globalize-accessors", "~> 0.3.0"
gem "graphiql-rails", "~> 1.8.0"
gem "graphql", "~> 2.4.11"
gem "groupdate", "~> 6.5.1"
gem "image_processing", "~> 1.13.0"
gem "invisible_captcha", "~> 2.3.0"
gem "kaminari", "~> 1.2.2"
gem "mini_magick", "~> 4.13.2"
gem "omniauth", "~> 2.1.2"
gem "omniauth-facebook", "~> 10.0.0"
gem "omniauth-google-oauth2", "~> 1.2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0.2"
gem "omniauth-twitter", "~> 1.4.0"
gem "paranoia", "~> 3.0.0"
gem "pg", "~> 1.5.8"
gem "pg_search", "~> 2.3.7"
gem "puma", "~> 5.6.9"
gem "recipient_interceptor", "~> 0.3.3"
gem "redcarpet", "~> 3.6.0"
gem "responders", "~> 3.1.1"
gem "rinku", "~> 2.0.6", require: "rails_rinku"
gem "ros-apartment", "~> 2.11.0", require: "apartment" # Remove ConnectionHandling monkey patch when upgrading
gem "sassc-embedded", "~> 1.77.5"
gem "sassc-rails", "~> 2.1.2"
gem "savon", "~> 2.15.1"
gem "sitemap_generator", "~> 6.3.0"
gem "social-share-button", "~> 1.2.4"
gem "sprockets", "~> 4.2.1"
gem "sprockets-rails", "~> 3.5.2", require: "sprockets/railtie"
gem "turbolinks", "~> 5.2.1"
gem "turnout", "~> 2.5.0"
gem "uglifier", "~> 4.2.1"
gem "uuidtools", "~> 2.2.0"
gem "view_component", "~> 3.11.0"
gem "whenever", "~> 1.0.0", require: false
gem "wicked_pdf", "~> 2.8.1"
gem "wkhtmltopdf-binary", "~> 0.12.6"

group :development, :test do
  gem "debug", "~> 1.9.2"
  gem "factory_bot_rails", "~> 6.4.4"
  gem "faker", "~> 3.5.1"
  gem "i18n-tasks", "~> 0.9.37"
  gem "knapsack_pro", "~> 7.8.0"
  gem "launchy", "~> 3.1.1"
  gem "letter_opener_web", "~> 3.0.0"
end

group :test do
  gem "capybara", "~> 3.40.0"
  gem "capybara-webmock", "~> 0.7.0"
  gem "email_spec", "~> 2.3.0"
  gem "pdf-reader", "~> 2.14.1"
  gem "rspec-rails", "~> 7.1.1"
  gem "selenium-webdriver", "~> 4.25.0"
  gem "simplecov", "~> 0.22.0", require: false
  gem "simplecov-lcov", "~> 0.8.0", require: false
end

group :development do
  gem "capistrano", "~> 3.19.2", require: false
  gem "capistrano-bundler", "~> 2.1.1", require: false
  gem "capistrano-npm", "~> 1.0.3", require: false
  gem "capistrano-rails", "~> 1.7.0", require: false
  gem "capistrano3-delayed-job", "~> 1.7.6"
  gem "capistrano3-puma", "~> 5.2.0"
  gem "erb_lint", "~> 0.9.0", require: false
  gem "faraday-retry", "~> 2.2.1", require: false
  gem "htmlbeautifier", "~> 1.4.3", require: false
  gem "mdl", "~> 0.13.0", require: false
  gem "pronto", "~> 0.11.2", require: false
  gem "pronto-erb_lint", "~> 0.1.6", require: false
  gem "pronto-eslint", "~> 0.11.1", require: false
  gem "pronto-rubocop", "~> 0.11.6", require: false
  gem "pronto-stylelint", "~> 0.11.0", require: false
  gem "rubocop", "~> 1.71.2", require: false
  gem "rubocop-capybara", "~> 2.21.0", require: false
  gem "rubocop-factory_bot", "~> 2.26.1", require: false
  gem "rubocop-performance", "~> 1.23.1", require: false
  gem "rubocop-rails", "~> 2.29.1", require: false
  gem "rubocop-rspec", "~> 3.4.0", require: false
  gem "rubocop-rspec_rails", "~> 2.30.0", require: false
  gem "rvm1-capistrano3", "~> 1.4.0", require: false
  gem "spring", "~> 4.2.1"
  gem "web-console", "~> 4.2.1"
end

eval_gemfile "./Gemfile_custom"
