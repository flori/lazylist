#!/usr/bin/env ruby

begin
  require 'rubygems'
rescue LoadError
end

$:.unshift File.expand_path(File.dirname($0))
$:.unshift 'lib'
$:.unshift 'tests'
require 'test'
require 'test_enumerable'

class TS_AllTests
  def self.suite
    suite = Test::Unit::TestSuite.new 'All tests'
    suite << TC_LazyList.suite
    suite << TC_LazyEnumerable.suite
  end
end
