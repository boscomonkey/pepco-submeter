#!/usr/bin/env ruby

require 'minitest/autorun'
require 'time'
require "#{File.expand_path(File.dirname __FILE__)}/../../lib/csv_converter"

class CsvConverterTest < Minitest::Test
  def setup
    @worker = CsvConverter.new
  end

  def test_process
    fname = 'test/fixtures/DEM_Report_10-02-13.csv'
    result = @worker.process(File.read fname)

    assert_equal ["NZA12",
                  "NZA13",
                  "NZA14",
                  "NZA17",
                  "NZA22",
                  "NZA23",
                  "NZB12",
                  "NZB13",
                  "NZB14",
                  "NZB17",
                  "NZB23",
                  "NZB28",
                  "NZBA22",
                  "SZD11",
                  "SZD12",
                  "SZD14",
                  "SZE13",
                  "SZE14",
                  "SZE22",
                  "WZC11",
                  "WZC12",
                  "WZC14",
                  "WZC22",
                  "WZC24",
                  "WZC25"],
                 result.points, 'points are wrong'
    assert_equal ["CONSUMPTN HI",
                  "CONSUMPTN LO",
                  "CURRENT A",
                  "CURRENT B",
                  "CURRENT C",
                  "DAY.NGT",
                  "DEMAND",
                  "POWER FACTOR",
                  "VOLTAGE A.N",
                  "VOLTAGE B.N",
                  "VOLTAGE C.N"],
                 result.channels, 'channels are wrong'
    assert_equal 95, result.data.size, 'INCORRECT TIMESTAMP COUNT'
  end

  def test_add_to_hash
    hsh = @worker.add_to_hash({}, 111, 222, 333, 444)
    expected = {111 => {222 => {333 => 444}}}
    assert_equal expected, hsh, 'INCORRECT HASH MAPPING'

    @worker.add_to_hash(hsh, 111, 222, 555, 666)
    expected2 = {111 => {222 => {333 => 444, 555 => 666}}}
    assert_equal expected2, hsh

    @worker.add_to_hash(hsh, 111, 777, 888, 999)
    expected3 = {111 => {
                   222 => {333 => 444, 555 => 666},
                   777 => {888 => 999},
                 }}
    assert_equal expected3, hsh

    @worker.add_to_hash(hsh, 'aaa', 'bbb', 'ccc', 'ddd')
    expected4 = {111 => {
                   222 => {333 => 444, 555 => 666},
                   777 => {888 => 999}},
                 'aaa' => {'bbb' => {'ccc' => 'ddd'}}
                }
    assert_equal expected4, hsh
  end

  def test_to_num
    assert_equal 1, @worker.to_num_if_possible('1'),
                 'failed integer conversion'
    assert_equal 1.1, @worker.to_num_if_possible('1.1'),
                 'failed float conversion'
  end

  def test_to_timestamp
    tstamp = @worker.to_timestamp('10/1/2013', '0:15:00')

    assert_equal Time.parse('Oct 1, 2013 00:15:00'), tstamp,
                 'parsing Pepco timestamp incorrectly'
  end
end
