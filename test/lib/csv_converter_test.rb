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
