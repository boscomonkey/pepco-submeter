#!/usr/bin/env ruby

require 'csv'

ARGF.each_line do |line|
  str_array = line.parse_csv
  puts str_array.join("\t")
end
