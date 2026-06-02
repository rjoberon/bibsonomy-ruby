require 'simplecov'
SimpleCov.start

require './lib/bibsonomy'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'
require 'coveralls'

Coveralls.wear!

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures"
  config.hook_into :webmock
end
