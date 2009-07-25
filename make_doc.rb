#!/usr/bin/env ruby

puts "Creating documentation."
system "rdoc -m doc-main.txt doc-main.txt #{Dir['lib/**/*.rb'] * ' '}"
