#!/usr/bin/env ruby

require File.expand_path(File.join('..', 'lib', 'matrix_formatter'),
                         File.dirname(__FILE__))

class FormatMatrix
  class DateMap < Struct.new(:filename, :pre, :match, :post, :timestamp)
  end

  def run(instream, outstream, prev_fname=nil)
    converter = CsvConverter.new
    prev_result = prev_fname ? converter.process(File.open prev_fname) : nil

    presult = converter.process(instream)
    consolidated = converter.consolidate_consumption(presult)
    stripped = converter.strip_channels(consolidated, "CONSUMPTN HI", "CONSUMPTN LO")

    formatter = MatrixFormatter.new
    formatter.output(outstream, stripped)
  end

  def find_previous_file(files_array)
    sorted_records = self.sort_files_by_date files_array
    rec = sorted_records.first

    prev_date = rec.timestamp.prev_day
    prev_str  = prev_date.strftime '%m-%d-%y'
    "#{rec.pre}#{prev_str}#{rec.post}"
  end

  def map_file_to_date(fname)
    if fname =~ /^(.*)(\d\d-\d\d-\d\d)(.*)$/
      pre   = $1
      match = $2
      post  = $3
      timestamp = Date.strptime match, '%m-%d-%y'

      DateMap.new fname, pre, match, post, timestamp
    end
  end

  def sort_files_by_date(files_array)
    date_maps = files_array.map {|fname| self.map_file_to_date(fname) }
    date_maps.sort {|a, b| a.timestamp <=> b.timestamp }
  end

end


if __FILE__ == $0
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] FILE1 FILE2 ...FILEn"

    opts.on("-f", "--force", "Runs regardless of warnings") do |force|
      options[:force] = force
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end

    opts.on("-pNAME", "--previous=NAME", "Name of previous file for CONSUMPTN") do |prev|
      options[:previous] = prev
    end
  end.parse!

  # figure out previous file
  app = FormatMatrix.new
  prev_fname = options[:previous]
  unless prev_fname
    filenames = [ARGF.filename] + ARGF.argv - ['-']
    if filenames.size > 0
      prev_fname = app.find_previous_file(filenames)
    end
  end

  app.run(ARGF, STDOUT, prev_fname)
end
