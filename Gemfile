# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: '.ruby-version'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.3'

# Use Postgres as the database for Active Record
gem 'pg', '~> 1.6.3'

# Geospatial column types and GeoJSON serialization
gem 'activerecord-postgis-adapter', '~> 11.1'
gem 'rgeo-geojson', '~> 2.2'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 8.0.2'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Json Web Token (JWT) for token based authentication
gem 'jwt', '~> 3.2'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.22'

# Transactional emails
gem 'postmark-rails', '~> 0.22.1'

# CSV processing
gem 'csv', '~> 3.3.5'

# Zip archive processing for imports and exports.
# Note: the gem is named `rubyzip` but ships `lib/zip.rb`, so the require path must be given.
gem 'rubyzip', '~> 2.3.2', require: 'zip'

# Resource API
gem 'resource_api', git: 'https://github.com/performant-software/resource-api.git', tag: 'v0.5.17'

# Authentication
gem 'jwt_auth', git: 'https://github.com/performant-software/jwt-auth.git', tag: 'v1.0.0'

# Record versioning / audit log
gem 'paper_trail', '>= 16.0'

# CORS for the public and reconciliation APIs
gem 'rack-cors', '~> 3.0.0', require: 'rack/cors'

# Typesense search and reconciliation
gem 'typesense', '~> 5.0'
gem 'typhoeus', '~> 1.6'

# IIIF
gem 'triple_eye_effable', git: 'https://github.com/performant-software/triple-eye-effable.git', tag: 'v0.2.9'

# User defined fields
gem 'user_defined_fields', git: 'https://github.com/performant-software/user-defined-fields.git', tag: 'v0.1.15'

# Fuzzy dates
gem 'fuzzy_dates', git: 'https://github.com/performant-software/fuzzy-dates.git', tag: 'v0.1.2'

# Email filtering
gem 'mail_safe', '~> 0.3.4', group: %i[development staging]

# Active storage service
gem 'aws-sdk-s3', '~> 1.193', group: [:production, :staging]

# Background jobs
gem 'sidekiq', '~> 8.0.6', group: [:production, :staging]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', '~> 1.11.0', platforms: %i[ mri mingw x64_mingw ]

  # Environment variable management
  gem 'dotenv-rails', '~> 3.2.0'
end

# ECDS STUFF
# gem 'core_data_connector_open_geographies', path: '/Users/jay/data/core-data-connector-open-geographies'
gem 'core_data_connector_open_geographies', git: 'https://github.com/ecds/core-data-connector-open-geographies.git', ref: '7dc6690'
# Elasticserch
gem 'elasticsearch', '~> 8.0'
gem 'faraday-typhoeus', '~> 1.0' # Needed to use Elasticsearch in rake tasks.
gem 'namae'
gem 'nameable'
gem 'aws-sdk'

# Geospatial libraries
gem 'concurrent-ruby', '1.3.4'
gem 'google_maps_service_ruby'
gem 'rgeo', '~> 3.0'
gem 'roo', '~> 2.10.0'
