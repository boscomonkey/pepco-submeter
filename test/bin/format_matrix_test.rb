#!/usr/bin/env ruby

require 'minitest/autorun'
require File.expand_path(File.join('..', '..', 'bin', 'format_matrix'),
                         File.dirname(__FILE__))

class FormatMatrixTest < Minitest::Test
  def setup
    @app = FormatMatrix.new
    @random_files = ["submetering/201401/DEM_Report_01-10-14.csv",
                     "submetering/201401/DEM_Report_01-06-15.csv",
                     "submetering/201401/DEM_Report_01-06-14.csv",
                     "submetering/201401/DEM_Report_01-08-14.csv",
                     "submetering/201401/DEM_Report_01-13-14.csv",
                     "submetering/201401/DEM_Report_01-09-14.csv",
                     "submetering/201401/DEM_Report_01-07-14.csv"]
  end

  def test_find_previous_file
    expected_file = "submetering/201401/DEM_Report_01-05-14.csv"
    assert_equal expected_file, @app.find_previous_file(@random_files)
  end

  def test_map_file_to_date
    expected_file = "submetering/201401/DEM_Report_01-05-14.csv"
    record = @app.map_file_to_date expected_file

    assert_equal expected_file, record.filename
    assert_equal Date.parse('2014-01-05'), record.timestamp
    assert_equal 'submetering/201401/DEM_Report_', record.pre
    assert_equal '01-05-14', record.match
    assert_equal '.csv', record.post
  end

  def test_sort_files_by_date
    sorted = @app.sort_files_by_date(@random_files)
    assert_equal "submetering/201401/DEM_Report_01-06-14.csv", sorted.first.filename
    assert_equal "submetering/201401/DEM_Report_01-06-15.csv", sorted.last.filename
  end
end
