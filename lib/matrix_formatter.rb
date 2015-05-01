require_relative 'csv_converter'

class MatrixFormatter

  def output(io, presult)
    arry = self.render(presult)
    arry.each {|row| io << row.to_csv}
    io
  end

  # Takes a CsvConverter::ProcessResult object and renders a 2D matrix
  # output as per Marty Burn's spec
  #
  def render(presult)
    self.render_headings(presult) + self.render_body(presult)
  end

  def render_headings(presult)
    [self.build_meter_heading(presult), self.build_channel_heading(presult)]
  end

  def render_body(presult)
    points = presult.points.sort
    channels = presult.channels.sort

    presult.data.keys.sort.map {|time|
      row = [self.build_timestamp_key(time)]
      points.each {|point|
        channels.each {|channel|
          row << ((points_table = presult.data[time]) &&
                  (channels_table = points_table[point]) ?
                    channels_table[channel] :
                    nil
                 )
          # row << presult.data[time][point][channel]
        }
      }

      row
    }
  end

  def build_channel_key(point, channel)
    "#{point}:#{channel}"
  end

  def build_channel_heading(presult)
    sorted_channels = presult.channels.sort
    matrix = presult.points.sort.map {|pt|
      sorted_channels.map {|chan|
        self.build_channel_key(pt, chan)
      }
    }
    ['Read Date Time '] + matrix.flatten
  end

  def build_meter_heading(presult)
    num_channels = presult.channels.size
    nil_arry = [nil]
    filler = nil_arry * (num_channels - 1)
    nil_arry + presult.points.map {|point| [self.build_meter_key(point)] + filler}.flatten
  end

  def build_meter_key(point)
    "Meter ID :  #{point}"
  end

  def build_timestamp_key(time)
    time.strftime '%m/%d/%Y %H:%M:%S'
  end

end


if __FILE__ == $0
  require 'minitest/autorun'
  require 'time'
  require 'yaml'

  class MatrixFormatterTest < Minitest::Test
    def setup
      @matfor = MatrixFormatter.new
    end

    def load_fixture
      fname = File.expand_path(File.join('..', 'test', 'fixtures', 'DEM_Report_10-02-13.yml'),
                                       File.dirname(__FILE__))
      fixture = YAML::load(File.read fname)
      assert_equal 95, fixture.data.size
      fixture
    end

    def test_render
      presult = load_fixture
      arry = @matfor.render(presult)

      assert_equal(presult.data.size + 2, arry.size,
                   '2 HEADING ROWS + NUMBER OF TIMESTAMPS')
    end

    def test_render_headings
      presult = load_fixture
      headers = @matfor.render_headings(presult)

      head1 = @matfor.build_meter_heading(presult)
      head2 = @matfor.build_channel_heading(presult)

      assert_equal [head1, head2], headers
    end

    def test_render_body
      presult = load_fixture
      body = @matfor.render_body(presult)

      assert_equal presult.data.keys.size, body.size
      assert_instance_of Array, body.first
      assert_equal(1 + presult.points.size * presult.channels.size, body.first.size)
    end

    def test_build_channel_key
      assert_equal 'NZA12:CONSUMPTN HI',
                   @matfor.build_channel_key('NZA12', 'CONSUMPTN HI'),
                   'INCORRECT CHANNEL KEY'
    end

    def test_build_channel_heading
      presult = load_fixture
      heading = @matfor.build_channel_heading(presult)
      assert_equal ['Read Date Time ',
                    [["NZA12:CONSUMPTN HI",
                      "NZA12:CONSUMPTN LO",
                      "NZA12:CURRENT A",
                      "NZA12:CURRENT B",
                      "NZA12:CURRENT C",
                      "NZA12:DAY.NGT",
                      "NZA12:DEMAND",
                      "NZA12:POWER FACTOR",
                      "NZA12:VOLTAGE A.N",
                      "NZA12:VOLTAGE B.N",
                      "NZA12:VOLTAGE C.N"],
                     ["NZA13:CONSUMPTN HI",
                      "NZA13:CONSUMPTN LO",
                      "NZA13:CURRENT A",
                      "NZA13:CURRENT B",
                      "NZA13:CURRENT C",
                      "NZA13:DAY.NGT",
                      "NZA13:DEMAND",
                      "NZA13:POWER FACTOR",
                      "NZA13:VOLTAGE A.N",
                      "NZA13:VOLTAGE B.N",
                      "NZA13:VOLTAGE C.N"],
                     ["NZA14:CONSUMPTN HI",
                      "NZA14:CONSUMPTN LO",
                      "NZA14:CURRENT A",
                      "NZA14:CURRENT B",
                      "NZA14:CURRENT C",
                      "NZA14:DAY.NGT",
                      "NZA14:DEMAND",
                      "NZA14:POWER FACTOR",
                      "NZA14:VOLTAGE A.N",
                      "NZA14:VOLTAGE B.N",
                      "NZA14:VOLTAGE C.N"],
                     ["NZA17:CONSUMPTN HI",
                      "NZA17:CONSUMPTN LO",
                      "NZA17:CURRENT A",
                      "NZA17:CURRENT B",
                      "NZA17:CURRENT C",
                      "NZA17:DAY.NGT",
                      "NZA17:DEMAND",
                      "NZA17:POWER FACTOR",
                      "NZA17:VOLTAGE A.N",
                      "NZA17:VOLTAGE B.N",
                      "NZA17:VOLTAGE C.N"],
                     ["NZA22:CONSUMPTN HI",
                      "NZA22:CONSUMPTN LO",
                      "NZA22:CURRENT A",
                      "NZA22:CURRENT B",
                      "NZA22:CURRENT C",
                      "NZA22:DAY.NGT",
                      "NZA22:DEMAND",
                      "NZA22:POWER FACTOR",
                      "NZA22:VOLTAGE A.N",
                      "NZA22:VOLTAGE B.N",
                      "NZA22:VOLTAGE C.N"],
                     ["NZA23:CONSUMPTN HI",
                      "NZA23:CONSUMPTN LO",
                      "NZA23:CURRENT A",
                      "NZA23:CURRENT B",
                      "NZA23:CURRENT C",
                      "NZA23:DAY.NGT",
                      "NZA23:DEMAND",
                      "NZA23:POWER FACTOR",
                      "NZA23:VOLTAGE A.N",
                      "NZA23:VOLTAGE B.N",
                      "NZA23:VOLTAGE C.N"],
                     ["NZB12:CONSUMPTN HI",
                      "NZB12:CONSUMPTN LO",
                      "NZB12:CURRENT A",
                      "NZB12:CURRENT B",
                      "NZB12:CURRENT C",
                      "NZB12:DAY.NGT",
                      "NZB12:DEMAND",
                      "NZB12:POWER FACTOR",
                      "NZB12:VOLTAGE A.N",
                      "NZB12:VOLTAGE B.N",
                      "NZB12:VOLTAGE C.N"],
                     ["NZB13:CONSUMPTN HI",
                      "NZB13:CONSUMPTN LO",
                      "NZB13:CURRENT A",
                      "NZB13:CURRENT B",
                      "NZB13:CURRENT C",
                      "NZB13:DAY.NGT",
                      "NZB13:DEMAND",
                      "NZB13:POWER FACTOR",
                      "NZB13:VOLTAGE A.N",
                      "NZB13:VOLTAGE B.N",
                      "NZB13:VOLTAGE C.N"],
                     ["NZB14:CONSUMPTN HI",
                      "NZB14:CONSUMPTN LO",
                      "NZB14:CURRENT A",
                      "NZB14:CURRENT B",
                      "NZB14:CURRENT C",
                      "NZB14:DAY.NGT",
                      "NZB14:DEMAND",
                      "NZB14:POWER FACTOR",
                      "NZB14:VOLTAGE A.N",
                      "NZB14:VOLTAGE B.N",
                      "NZB14:VOLTAGE C.N"],
                     ["NZB17:CONSUMPTN HI",
                      "NZB17:CONSUMPTN LO",
                      "NZB17:CURRENT A",
                      "NZB17:CURRENT B",
                      "NZB17:CURRENT C",
                      "NZB17:DAY.NGT",
                      "NZB17:DEMAND",
                      "NZB17:POWER FACTOR",
                      "NZB17:VOLTAGE A.N",
                      "NZB17:VOLTAGE B.N",
                      "NZB17:VOLTAGE C.N"],
                     ["NZB23:CONSUMPTN HI",
                      "NZB23:CONSUMPTN LO",
                      "NZB23:CURRENT A",
                      "NZB23:CURRENT B",
                      "NZB23:CURRENT C",
                      "NZB23:DAY.NGT",
                      "NZB23:DEMAND",
                      "NZB23:POWER FACTOR",
                      "NZB23:VOLTAGE A.N",
                      "NZB23:VOLTAGE B.N",
                      "NZB23:VOLTAGE C.N"],
                     ["NZB28:CONSUMPTN HI",
                      "NZB28:CONSUMPTN LO",
                      "NZB28:CURRENT A",
                      "NZB28:CURRENT B",
                      "NZB28:CURRENT C",
                      "NZB28:DAY.NGT",
                      "NZB28:DEMAND",
                      "NZB28:POWER FACTOR",
                      "NZB28:VOLTAGE A.N",
                      "NZB28:VOLTAGE B.N",
                      "NZB28:VOLTAGE C.N"],
                     ["NZBA22:CONSUMPTN HI",
                      "NZBA22:CONSUMPTN LO",
                      "NZBA22:CURRENT A",
                      "NZBA22:CURRENT B",
                      "NZBA22:CURRENT C",
                      "NZBA22:DAY.NGT",
                      "NZBA22:DEMAND",
                      "NZBA22:POWER FACTOR",
                      "NZBA22:VOLTAGE A.N",
                      "NZBA22:VOLTAGE B.N",
                      "NZBA22:VOLTAGE C.N"],
                     ["SZD11:CONSUMPTN HI",
                      "SZD11:CONSUMPTN LO",
                      "SZD11:CURRENT A",
                      "SZD11:CURRENT B",
                      "SZD11:CURRENT C",
                      "SZD11:DAY.NGT",
                      "SZD11:DEMAND",
                      "SZD11:POWER FACTOR",
                      "SZD11:VOLTAGE A.N",
                      "SZD11:VOLTAGE B.N",
                      "SZD11:VOLTAGE C.N"],
                     ["SZD12:CONSUMPTN HI",
                      "SZD12:CONSUMPTN LO",
                      "SZD12:CURRENT A",
                      "SZD12:CURRENT B",
                      "SZD12:CURRENT C",
                      "SZD12:DAY.NGT",
                      "SZD12:DEMAND",
                      "SZD12:POWER FACTOR",
                      "SZD12:VOLTAGE A.N",
                      "SZD12:VOLTAGE B.N",
                      "SZD12:VOLTAGE C.N"],
                     ["SZD14:CONSUMPTN HI",
                      "SZD14:CONSUMPTN LO",
                      "SZD14:CURRENT A",
                      "SZD14:CURRENT B",
                      "SZD14:CURRENT C",
                      "SZD14:DAY.NGT",
                      "SZD14:DEMAND",
                      "SZD14:POWER FACTOR",
                      "SZD14:VOLTAGE A.N",
                      "SZD14:VOLTAGE B.N",
                      "SZD14:VOLTAGE C.N"],
                     ["SZE13:CONSUMPTN HI",
                      "SZE13:CONSUMPTN LO",
                      "SZE13:CURRENT A",
                      "SZE13:CURRENT B",
                      "SZE13:CURRENT C",
                      "SZE13:DAY.NGT",
                      "SZE13:DEMAND",
                      "SZE13:POWER FACTOR",
                      "SZE13:VOLTAGE A.N",
                      "SZE13:VOLTAGE B.N",
                      "SZE13:VOLTAGE C.N"],
                     ["SZE14:CONSUMPTN HI",
                      "SZE14:CONSUMPTN LO",
                      "SZE14:CURRENT A",
                      "SZE14:CURRENT B",
                      "SZE14:CURRENT C",
                      "SZE14:DAY.NGT",
                      "SZE14:DEMAND",
                      "SZE14:POWER FACTOR",
                      "SZE14:VOLTAGE A.N",
                      "SZE14:VOLTAGE B.N",
                      "SZE14:VOLTAGE C.N"],
                     ["SZE22:CONSUMPTN HI",
                      "SZE22:CONSUMPTN LO",
                      "SZE22:CURRENT A",
                      "SZE22:CURRENT B",
                      "SZE22:CURRENT C",
                      "SZE22:DAY.NGT",
                      "SZE22:DEMAND",
                      "SZE22:POWER FACTOR",
                      "SZE22:VOLTAGE A.N",
                      "SZE22:VOLTAGE B.N",
                      "SZE22:VOLTAGE C.N"],
                     ["WZC11:CONSUMPTN HI",
                      "WZC11:CONSUMPTN LO",
                      "WZC11:CURRENT A",
                      "WZC11:CURRENT B",
                      "WZC11:CURRENT C",
                      "WZC11:DAY.NGT",
                      "WZC11:DEMAND",
                      "WZC11:POWER FACTOR",
                      "WZC11:VOLTAGE A.N",
                      "WZC11:VOLTAGE B.N",
                      "WZC11:VOLTAGE C.N"],
                     ["WZC12:CONSUMPTN HI",
                      "WZC12:CONSUMPTN LO",
                      "WZC12:CURRENT A",
                      "WZC12:CURRENT B",
                      "WZC12:CURRENT C",
                      "WZC12:DAY.NGT",
                      "WZC12:DEMAND",
                      "WZC12:POWER FACTOR",
                      "WZC12:VOLTAGE A.N",
                      "WZC12:VOLTAGE B.N",
                      "WZC12:VOLTAGE C.N"],
                     ["WZC14:CONSUMPTN HI",
                      "WZC14:CONSUMPTN LO",
                      "WZC14:CURRENT A",
                      "WZC14:CURRENT B",
                      "WZC14:CURRENT C",
                      "WZC14:DAY.NGT",
                      "WZC14:DEMAND",
                      "WZC14:POWER FACTOR",
                      "WZC14:VOLTAGE A.N",
                      "WZC14:VOLTAGE B.N",
                      "WZC14:VOLTAGE C.N"],
                     ["WZC22:CONSUMPTN HI",
                      "WZC22:CONSUMPTN LO",
                      "WZC22:CURRENT A",
                      "WZC22:CURRENT B",
                      "WZC22:CURRENT C",
                      "WZC22:DAY.NGT",
                      "WZC22:DEMAND",
                      "WZC22:POWER FACTOR",
                      "WZC22:VOLTAGE A.N",
                      "WZC22:VOLTAGE B.N",
                      "WZC22:VOLTAGE C.N"],
                     ["WZC24:CONSUMPTN HI",
                      "WZC24:CONSUMPTN LO",
                      "WZC24:CURRENT A",
                      "WZC24:CURRENT B",
                      "WZC24:CURRENT C",
                      "WZC24:DAY.NGT",
                      "WZC24:DEMAND",
                      "WZC24:POWER FACTOR",
                      "WZC24:VOLTAGE A.N",
                      "WZC24:VOLTAGE B.N",
                      "WZC24:VOLTAGE C.N"],
                     ["WZC25:CONSUMPTN HI",
                      "WZC25:CONSUMPTN LO",
                      "WZC25:CURRENT A",
                      "WZC25:CURRENT B",
                      "WZC25:CURRENT C",
                      "WZC25:DAY.NGT",
                      "WZC25:DEMAND",
                      "WZC25:POWER FACTOR",
                      "WZC25:VOLTAGE A.N",
                      "WZC25:VOLTAGE B.N",
                      "WZC25:VOLTAGE C.N"]]
                   ].flatten,
                   heading,
                   'INCORRECT CHANNEL HEADING'
    end

    def test_meter_heading
      presult = load_fixture
      heading = @matfor.build_meter_heading(presult)

      assert_equal [nil,
                    "Meter ID :  NZA12", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZA13", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZA14", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZA17", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZA22", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZA23", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB12", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB13", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB14", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB17", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB23", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZB28", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  NZBA22", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZD11", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZD12", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZD14", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZE13", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZE14", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  SZE22", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC11", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC12", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC14", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC22", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC24", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                    "Meter ID :  WZC25", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil], heading,
                   'INCORRECT METER HEADING'
    end

    def test_meter_key
      assert_equal 'Meter ID :  DUMMYPOINT', @matfor.build_meter_key('DUMMYPOINT'),
                   'INCORRECT "Meter ID" KEY'
    end

    def test_build_timestamp_key
      time = Time.parse "Oct 1, 2013 11:30:01 PM"
      assert_equal "10/01/2013 23:30:01", @matfor.build_timestamp_key(time)
    end
  end

end
