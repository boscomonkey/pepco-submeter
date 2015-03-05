#!/usr/bin/env ruby

ARGF.each_line do |line|
  if line =~ /Point Name:/
    ignored, colon_separated = line.split /\t/
    puts colon_separated.sub(':', "\t")
  end
end
