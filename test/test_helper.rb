require 'simplecov'
SimpleCov.start

require './lib/bibsonomy'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'
require 'coveralls'

Coveralls.wear!

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures"
  c.hook_into :webmock
end
