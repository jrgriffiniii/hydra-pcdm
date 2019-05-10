source 'https://rubygems.org'

group :development, :test do
  gem 'bixby', '~> 1.0'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'rspec_junit_formatter'
end

# Specify your gem's dependencies in hydra-pcdm.gemspec
gemspec

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
