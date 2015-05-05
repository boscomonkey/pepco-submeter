#!/usr/bin/env ruby

require 'optparse'
require 'time'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-f", "--force", "Runs regardless of warnings") do |force|
    options[:force] = force
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

all_files = [ARGF.filename] + ARGF.argv
timestamped = all_files.map do |fname|
  if fname =~ /^(.*)(\d\d-\d\d-\d\d)(.*)$/
    before = $1
    middle = $2
    after  = $3

    timestamp = Time.strptime middle, '%m-%d-%y'
    {filename: fname, timestamp: timestamp}
  end
end
sorted_duples = timestamped.sort {|a, b| a[:timestamp] <=> b[:timestamp]}
puts sorted_duples.map {|duple| duple[:filename]}

duple = sorted.first
timestamp = duple[:timestamp]
exit

curr_filename = nil
ARGF.each_line do |line|
  if ARGF.filename != curr_filename
    curr_filename = ARGF.filename

    clump = [curr_filename]		# + ARGF.argv
    puts clump.join("\n\t")
  end
end
