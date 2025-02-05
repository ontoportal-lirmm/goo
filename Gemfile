source 'https://rubygems.org'

gemspec

gem "activesupport"
gem "cube-ruby", require: "cube"
gem "rake"
gem "uuid"
gem "request_store"

group :test do
  gem "minitest", '< 5.0'
  gem "pry"
  gem 'simplecov'
  gem 'simplecov-cobertura' # for submitting code coverage results to codecov.io
end

group :profiling do
  gem "rack-accept"
  gem "rack-post-body-to-params"
  gem "sinatra"
  gem "thin"
end

gem 'sparql-client', github: 'ontoportal-lirmm/sparql-client', branch: 'development'
gem 'faraday', '2.7.11' #unpin if we no more support ruby 2.7
gem "rdf-raptor", github: "ruby-rdf/rdf-raptor", ref: "6392ceabf71c3233b0f7f0172f662bd4a22cd534" # use version 3.3.0 when available
