require 'test/unit'
require 'pp'

require_relative '../config/config.rb'

STDOUT.sync = true

Dir.glob(File.absolute_path(File.dirname(__FILE__)+'/../lib/*.rb'), &method(:require))

def fixture_path(path = "")
  File.absolute_path(File.join(File.dirname(__FILE__), "fixtures", path))
end
