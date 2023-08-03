# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1', '>= 6.1.3.1'
gem 'sqlite3', '~> 1.4.1'

gem 'carrierwave', '1.2.0'
gem 'carrierwave-google-storage', '0.9.0'
gem 'coffee-rails'
gem 'dotenv-rails'
gem 'file_validators', '2.3.0'
gem 'honeybadger'
gem 'jbuilder', '~> 2.9', '>= 2.9.0'
gem 'materialize-sass', '1.0'
gem 'puma', '~> 5.6'
gem 'sass-rails'
gem 'settingslogic', '~> 2.0.9'
gem 'sidekiq', '~> 5.2.10'
gem 'turbolinks', '~> 5'
gem 'typhoeus', '~> 1.3'
gem 'uglifier', '>= 1.3.0'

gem 'google-cloud-storage', '~> 1.10'
gem 'google-cloud-translate',  '~> 1.3'
gem 'google-cloud-vision', '~> 0.32.2'
gem 'google_drive', '~> 3.0.3'
gem 'rmagick'

gem 'redis'
gem 'redis-namespace'
gem 'redis-objects', '~> 1.4.3'
gem 'redis-rack-cache', '>= 2.1.0'
gem 'redis-rails', '>= 5.0.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :development, :test do
  gem 'brakeman', '>= 4.7.1', require: false
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'faker'
  gem 'guard', '~> 2.14', '>= 2.14.2', require: false
  gem 'guard-bundler', '~> 2.1', require: false
  gem 'guard-rspec', '~> 4.7', '>= 4.7.3', require: false
  gem 'guard-rubocop', '~> 1.3', require: false
  gem 'rubocop', '~> 0.57.2', require: false
  gem 'rubocop-rspec', '= 1.21'
end

group :test do
  gem 'database_cleaner', require: false # clean database
  gem 'factory_bot_rails', require: false
  gem 'fakeredis', require: 'fakeredis/rspec'
  gem 'pry'
  gem 'rails-controller-testing', '>= 1.0.4'
  gem 'rspec-mocks', '~> 3.7', require: false
  gem 'rspec-rails', '~> 5.0', '>= 5.0.1'
  gem 'shoulda-matchers', '>= 4.0.1'
  gem 'simplecov', require: false
  gem 'timecop', require: false
  gem 'vcr', require: false
  gem 'webmock'
end
