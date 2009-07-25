#!/usr/bin/env ruby

require 'rbconfig'
include Config
require 'fileutils'
include FileUtils::Verbose

libdir = CONFIG["sitelibdir"]
install("lib/lazylist.rb", libdir)
mkdir_p subdir = File.join(libdir, 'lazylist')
for f in Dir['lib/lazylist/*.rb']
  install(f, subdir)
end
