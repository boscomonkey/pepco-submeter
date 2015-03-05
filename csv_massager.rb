#!/usr/bin/env ruby

require 'csv'

class CsvMassager

  def flatten(instream)
    buffer = []
    zone, aspect = nil, nil
    instream.each_line do |line|
      arry = line.parse_csv

      case arry.first
      when 'Point Name:'
        # "Point Name:","NZA12:CONSUMPTN HI"
        # split the 2nd element of the array, not the last
        zone, aspect = arry[1].split ':'
      when 'Trend Every:', 'Date Range:', 'Report Timings:', /^ \*{8,}/
        # ignore
      when '', nil
        # also ignore
      when /^\d+\/\d+\/\d+$/
        arry.insert 1, zone, aspect
        buffer << arry
      else
        raise "Unknown Line Format:\t#{line}"
      end
    end

    buffer
  end

end


if __FILE__ == $0

  if ARGV.length == 1
    # if there is 1 argument, run the code
    fname = ARGV[0]
    massager = CsvMassager.new
    arry = massager.flatten(File.read fname)

    arry.each {|row| puts row.to_csv}
  else
    # no command line arg, run unit test
    require 'minitest/autorun'

    class Test < Minitest::Test
      def test_flatten
        fname = 'test/fixtures/DEM_Report_10-02-13.csv'
        massager = CsvMassager.new
        out = massager.flatten(File.read fname)

        assert out.length > 0, 'output should be non-empty'
        assert_equal out.first, ["10/1/2013","NZA12","CONSUMPTN HI","0:00:00","630784"," -N-       NONE"]
      end
    end
  end

end
