#!/usr/bin/env ruby

require 'csv'
require 'set'
require 'time'

class CsvConverter
  class ProcessResult < Struct.new(:channels, :points, :data); end

  class RowsBuffer < Array
    alias :append	:<<
    alias :flush	:clear

    def initialize(converter)
      @converter = converter
    end

    def write(hash3d, curr_point, curr_channel)
      unless self.empty?
        self.each do |row|
          dt, tm, val = row
          timestamp = @converter.to_timestamp(dt, tm)
          data = @converter.to_num_if_possible(val)
          
          @converter.add_to_hash(hash3d, timestamp, curr_point, curr_channel, data)
        end

        self.flush
      end
    end
  end

  def process(instream)
    hash3 = {}		# timestamp -> {point -> {channel -> data}}
    channels_set = Set.new
    points_set = Set.new
    curr_channel = nil
    curr_point = nil
    rows_buffer = RowsBuffer.new(self)

    instream.each_line do |line|
      row = line.parse_csv

      case row.first
      when 'Point Name:'
        rows_buffer.write(hash3, curr_point, curr_channel)

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

      when /^Data Loss$/
        # "Data Loss": dump all currently buffered lines
        rows_buffer.flush

      when /^No data in range specified\./
        # ignore "No data in range specified."

      when /^\d+\/\d+\/\d+$/
        # 10/1/2013,0:00:00,630784, -N-       NONE
        rows_buffer.append row

      else
        raise "Unknown Line Format (#{instream.path}: #{instream.lineno}):\t#{line}"
      end
    end

    rows_buffer.write(hash3, curr_point, curr_channel)
    ProcessResult.new(channels_set.sort, points_set.sort, hash3)
  end

  def consolidate_consumption(presult)
    if presult.channels.include?('CONSUMPTN HI') \
       && presult.channels.include?('CONSUMPTN LO')

      # create new CONSUMPTN channel
      extended = presult.channels + ['CONSUMPTN']
      sorted   = extended.sort
      presult.channels = sorted

      # create channel data
      time_asc = presult.data.keys.sort
      time_asc.each_with_index do |tm, ii|
        points_matrix = presult.data[tm]
        points_matrix.each do |pt, chans|
          if 0 == ii
            chans['CONSUMPTN'] = nil
          else
            prev_time  = time_asc[ii - 1]
            prev_chans = presult.data[prev_time][pt]
            if (prev_hi = prev_chans['CONSUMPTN HI']) \
               && (prev_lo = prev_chans['CONSUMPTN LO']) \
               && (curr_hi = chans['CONSUMPTN HI']) \
               && (curr_lo = chans['CONSUMPTN LO'])
              chans['CONSUMPTN'] = (curr_hi + curr_lo) - (prev_hi + prev_lo)
            end
          end
        end
      end
    end

    presult	# for convenient chaining
  end

  def strip_channels(presult, *channels)
    presult.channels -= channels
    presult	# for convenient chaining
  end

  def add_to_hash(hsh, timestamp, point, channel, data)
    # mappings: timestamp -> {point -> {channel -> data}}
    hsh[timestamp] = Hash.new unless hsh.has_key?(timestamp)
    hsh[timestamp][point] = Hash.new unless hsh[timestamp].has_key?(point)
    hsh[timestamp][point][channel] = data

    hsh
  end

  def round_off_seconds(timestamp)
    seconds = timestamp.to_i		# round off milliseconds
    minutes = seconds.to_f / 60		# result in float
    nearest_min = minutes.round
    rounded_secs = nearest_min * 60
    Time.at rounded_secs
  end

  def to_key(str)
    str.strip.upcase
  end

  def to_num_if_possible(str)
    ((float = Float(str)) &&
     (float % 1.0 == 0) ? float.to_i : float) rescue str
  end

  def to_timestamp(date_str, time_str)
    # may be off by seconds
    tm = Time.strptime "#{date_str} #{time_str}", '%m/%d/%Y %H:%M:%S'

    # round to nearest minute if seconds aren't "00"
    ":00" == time_str[-3,3] ? tm : self.round_off_seconds(tm)
  end

end
