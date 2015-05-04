#!/usr/bin/env ruby

require 'minitest/autorun'
require File.expand_path(File.join('..', '..', 'lib', 'csv_converter'),
                         File.dirname(__FILE__))

class CsvConverterTest < Minitest::Test
  def setup
    @cc = CsvConverter.new
  end

  def test_process
    fname = 'test/fixtures/DEM_Report_10-02-13.csv'
    result = @cc.process(File.read fname)

    expected_points = ["NZA12", "NZA13", "NZA14", "NZA17", "NZA22",
                       "NZA23", "NZB12", "NZB13", "NZB14", "NZB17",
                       "NZB23", "NZB28", "NZBA22", "SZD11", "SZD12",
                       "SZD14", "SZE13", "SZE14", "SZE22", "WZC11",
                       "WZC12", "WZC14", "WZC22", "WZC24", "WZC25"]
    expected_channels = ["CONSUMPTN HI", "CONSUMPTN LO", "CURRENT A",
                         "CURRENT B", "CURRENT C", "DAY.NGT", "DEMAND",
                         "POWER FACTOR", "VOLTAGE A.N", "VOLTAGE B.N",
                         "VOLTAGE C.N"]

    assert_equal expected_points, result.points, 'points are wrong'
    assert_equal expected_channels, result.channels, 'channels are wrong'
    assert_equal 95, result.data.size, 'INCORRECT TIMESTAMP COUNT'

    tstamp = result.data.keys.first
    assert_equal Time.parse('2013-10-01 00:00:00 -0400'), tstamp
    assert_equal expected_points.size, result.data[tstamp].size, "TIME KEY: #{tstamp}"
  end

  def test_consolidate_consumption
    fname = 'test/fixtures/DEM_Report_10-02-13.csv'
    result = @cc.process(File.read fname)
    consolidated = @cc.consolidate_consumption(result)

    expected_channels = ["CONSUMPTN", "CONSUMPTN HI", "CONSUMPTN LO",
                         "CURRENT A", "CURRENT B", "CURRENT C",
                         "DAY.NGT", "DEMAND", "POWER FACTOR",
                         "VOLTAGE A.N", "VOLTAGE B.N", "VOLTAGE C.N"]
    assert_equal expected_channels, consolidated.channels

    # each data point at each time should have extra channel dimension
    consolidated.data.each do |timestamp, points_matrix|
      points_matrix.each do |pointname, channels_data|
        if channels_data.include?('CONSUMPTN HI') && channels_data.include?('CONSUMPTN LO')
          assert channels_data.include?('CONSUMPTN'), "include? #{timestamp} :: #{pointname}"

          if timestamp == consolidated.data.keys.first
            # first timestamp should be nil
            assert_nil channels_data['CONSUMPTN'], "assert_nil: #{timestamp} :: #{pointname}"
          else
            # remaining timestamps are not nil
            refute_nil channels_data['CONSUMPTN'], "refute_nil: #{timestamp} :: #{pointname}"
          end
        end
      end
    end

    # compare data for NZA12
    expected_consumption = [nil, 3, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,
                            5, 4, 5, 5, 4, 5, 4, 5, 4, 5, 4, 5, 6, 6,
                            6, 5, 7, 8, 8, 8, 9, 9, 11, 11, 12, 13,
                            13, 13, 14, 13, 13, 13, 13, 14, 13, 13,
                            13, 13, 13, 13, 13, 13, 13, 13, 13, 12,
                            13, 12, 12, 13, 13, 12, 11, 12, 11, 11,
                            10, 10, 8, 8, 7, 6, 7, 6, 6, 6, 5, 5, 5,
                            5, 4, 4, 3, 3, 4, 3, 4, 3, 3, 3]
    test_consumption = consolidated.data.reduce([]) do |memo, pair|
      timestamp     = pair[0]
      points_matrix = pair[1]
      assert_instance_of Hash, points_matrix

      if channels = points_matrix['NZA12']
        assert_instance_of Hash, channels, "DIE :: #{timestamp} :: #{memo.size}"

        memo << channels['CONSUMPTN']
      else
        memo
      end
    end
    assert_equal expected_consumption, test_consumption
  end

  def test_strip_channels
    fname = 'test/fixtures/DEM_Report_10-02-13.csv'
    result = @cc.process(File.read fname)
    stripped_result = @cc.strip_channels(result, "CONSUMPTN HI", "CONSUMPTN LO")

    expected_channels = ["CURRENT A", "CURRENT B", "CURRENT C",
                         "DAY.NGT", "DEMAND", "POWER FACTOR",
                         "VOLTAGE A.N", "VOLTAGE B.N", "VOLTAGE C.N"]
    assert_equal expected_channels, stripped_result.channels
  end

  def test_data_loss
    fname = 'test/fixtures/data-loss_DEM_Report_11-03-14.csv'
    File.open(fname) do |fin|
      result = @cc.process fin

      assert_equal 24*4, result.data.size
    end
  end

  def test_unknown_line_format
    fname = 'test/fixtures/test-data-loss.csv'
    err = assert_raises(RuntimeError) {
      File.open(fname) {|fin| @cc.process fin }
    }
    assert_match /Unknown Line Format \(test\/fixtures\/test-data-loss.csv: 114\):\W+Test Data Loss/, err.message
  end

  def test_add_to_hash
    hsh = @cc.add_to_hash({}, 111, 222, 333, 444)
    expected = {111 => {222 => {333 => 444}}}
    assert_equal expected, hsh, 'INCORRECT HASH MAPPING'

    @cc.add_to_hash(hsh, 111, 222, 555, 666)
    expected2 = {111 => {222 => {333 => 444, 555 => 666}}}
    assert_equal expected2, hsh

    @cc.add_to_hash(hsh, 111, 777, 888, 999)
    expected3 = {111 => {
                   222 => {333 => 444, 555 => 666},
                   777 => {888 => 999},
                 }}
    assert_equal expected3, hsh

    @cc.add_to_hash(hsh, 'aaa', 'bbb', 'ccc', 'ddd')
    expected4 = {111 => {
                   222 => {333 => 444, 555 => 666},
                   777 => {888 => 999}},
                 'aaa' => {'bbb' => {'ccc' => 'ddd'}}
                }
    assert_equal expected4, hsh
  end

  def test_to_num
    assert_equal 1, @cc.to_num_if_possible('1'),
                 'failed integer conversion'
    assert_equal 1.1, @cc.to_num_if_possible('1.1'),
                 'failed float conversion'
  end

  def test_to_timestamp
    tstamp = @cc.to_timestamp('10/1/2013', '0:15:00')

    assert_equal Time.parse('Oct 1, 2013 00:15:00'), tstamp,
                 'parsing Pepco timestamp incorrectly'
  end

  def test_round_off_seconds_after
    tstamp = Time.parse('Oct 1, 2013 00:15:01')
    expected = Time.parse('Oct 1, 2013 00:15:00')

    assert_equal expected, @cc.round_off_seconds(tstamp)
  end

  def test_round_off_seconds_before
    tstamp = Time.parse('Oct 1, 2013 00:14:59')
    expected = Time.parse('Oct 1, 2013 00:15:00')

    assert_equal expected, @cc.round_off_seconds(tstamp)
  end

  def test_accrue_seconds_to_nearest_hour
    fname = 'test/fixtures/zero-minutes.csv'
    result = @cc.process(File.read fname)

    # there should only be 4 different timestamps
    time_hash = result.data
    assert_equal 4, time_hash.keys.size
  end

  def test_no_data_in_range
    fname = 'test/fixtures/no-data-in-range_DEM_Report_07-28-14.csv'
    result = @cc.process(File.read fname)

    assert_equal 0, result.data.size
  end
end
