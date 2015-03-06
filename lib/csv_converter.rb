#!/usr/bin/env ruby

require 'csv'
require 'set'

class CsvConverter
  class ProcessResult < Struct.new(:channels, :points, :data); end

  def process(instream)
    hash3 = {}		# timestamp -> {point -> {channel -> data}}
    channels_set = Set.new
    points_set = Set.new
    curr_channel = nil
    curr_point = nil

    instream.each_line do |line|
      row = line.parse_csv

      case row.first
      when 'Point Name:'
        # "Point Name:","NZA12:CONSUMPTN HI"
        # split the 2nd element of the row, not the last element
        point, channel = row[1].split ':'

        curr_point = self.to_key(point)
        curr_channel = self.to_key(channel)

        channels_set << curr_channel
        points_set << curr_point
      when 'Trend Every:', 'Date Range:', 'Report Timings:'
        # ignore extra headings
      when '', nil
        # ignore blanks
      when /^ \*{30,}/
        # ignore asterisk separators
      when /^\d+\/\d+\/\d+$/
        # 10/1/2013,0:00:00,630784, -N-       NONE
        dt, tm, val = row
        timestamp = self.to_timestamp(dt, tm)
        data = self.to_num_if_possible(val)
        
        self.add_to_hash(hash3, timestamp, curr_point, curr_channel, data)
      else
        raise "Unknown Line Format:\t#{line}"
      end
    end

    ProcessResult.new(channels_set.sort, points_set.sort, hash3)
  end

  def add_to_hash(hsh, timestamp, point, channel, data)
    # mappings: timestamp -> {point -> {channel -> data}}
    hsh[timestamp] = Hash.new unless hsh.has_key?(timestamp)
    hsh[timestamp][point] = Hash.new unless hsh[timestamp].has_key?(point)
    hsh[timestamp][point][channel] = data

    hsh
  end

  def to_key(str)
    str.strip.upcase
  end

  def to_num_if_possible(str)
    ((float = Float(str)) &&
     (float % 1.0 == 0) ? float.to_i : float) rescue str
  end

  def to_timestamp(date_str, time_str)
    Time.strptime "#{date_str} #{time_str}", '%m/%d/%Y %H:%M:%S'
  end

end
