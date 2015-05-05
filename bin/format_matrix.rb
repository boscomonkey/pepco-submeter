#!/usr/bin/env ruby

require File.expand_path(File.join('..', 'lib', 'matrix_formatter'),
                         File.dirname(__FILE__))

class FormatMatrix
  class DateMap < Struct.new(:filename, :pre, :match, :post, :timestamp)
  end

  def run(instream, outstream, prev_fname)
    converter = CsvConverter.new
    curr_result = converter.process(instream)

    # point cut - pre consolidate
    if prev_fname && File.exists?(prev_fname)
      tstamp = self.previous_timestamp(curr_result.data.keys.first)
      prev_result = converter.process(File.open prev_fname)
      if prev_points_matrix = prev_result.data[tstamp]
        curr_result.data[tstamp] = prev_points_matrix
      end
    end

    consolidated = converter.consolidate_consumption(curr_result)
    converter.strip_channels(consolidated, "CONSUMPTN HI", "CONSUMPTN LO")

    # point cut - post consolidate
    if prev_fname && File.exists?(prev_fname)
      curr_result.data.delete tstamp
    end

    formatter = MatrixFormatter.new
    formatter.output(outstream, consolidated)
  end

  def find_previous_file(prev_file)
    if prev_file.nil?
      self.guess_previous_file(self.get_argf_filenames)
    else
      prev_file
    end
  end

  def get_argf_filenames
    [ARGF.filename] + ARGF.argv - ['-']
  end

  def guess_previous_file(existing_files)
    sorted_records = self.build_sorted_records existing_files
    if rec = sorted_records.first
      prev_date = rec.timestamp.prev_day
      prev_str  = prev_date.strftime '%m-%d-%y'
      "#{rec.pre}#{prev_str}#{rec.post}"
    end
  end

  def build_rich_record(fname)
    if fname =~ /^(.*)(\d\d-\d\d-\d\d)(.*)$/
      pre   = $1
      match = $2
      post  = $3
      timestamp = Date.strptime match, '%m-%d-%y'

      DateMap.new fname, pre, match, post, timestamp
    else
      raise "BADLY FORMED FILENAME: #{fname}"
    end
  end

  def build_sorted_records(existing_files)
    date_maps = existing_files.map {|fname| self.build_rich_record(fname) }
    date_maps.sort {|a, b| a.timestamp <=> b.timestamp }
  end

  def previous_timestamp(tm)
    tm - 15 * 60
  end
end


if __FILE__ == $0
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] [FILE1 FILE2 ... FILEn]"

    # opts.on("-f", "--force", "Runs regardless of warnings") do |force|
    #   options[:force] = force
    # end

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
  prev_fname = app.find_previous_file(options[:previous])	# may still be nil

  app.run(ARGF, STDOUT, prev_fname)
end
