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

  def test_find_previous_file_with_nonnil_arg
    prev_file = "submetering/201401/DEM_Report_01-05-14.csv"
    assert_equal prev_file, @app.find_previous_file(prev_file)
  end

  def test_find_previous_file_with_nil_arg
    assert_nil @app.find_previous_file(nil)
  end

  def test_find_previous_file_with_nil_arg_stubbing_get_argf_filenames
    #
    # stub get_argf_filenames for this instance of @app
    #
    stubbed_filenames = ["DEM_Report_01-09-14.csv", "DEM_Report_01-07-14.csv"]
    @app.stub(:get_argf_filenames, stubbed_filenames) do
      assert_equal 'DEM_Report_01-06-14.csv', @app.find_previous_file(nil)
    end
  end

  def test_get_argf_filenames
    assert_equal [], @app.get_argf_filenames
  end

  def test_guess_previous_file
    expected_file = "submetering/201401/DEM_Report_01-05-14.csv"
    assert_equal expected_file, @app.guess_previous_file(@random_files)
  end

  def test_build_rich_record
    expected_file = "submetering/201401/DEM_Report_01-05-14.csv"
    record = @app.build_rich_record expected_file

    assert_equal expected_file, record.filename
    assert_equal Date.parse('2014-01-05'), record.timestamp
    assert_equal 'submetering/201401/DEM_Report_', record.pre
    assert_equal '01-05-14', record.match
    assert_equal '.csv', record.post
  end

  def test_build_rich_record_badly_formatted_filename
    assert_raises(RuntimeError) do
      @app.build_rich_record "dummy_file_mm-dd-yy.csv"
    end
  end

  def test_build_sorted_records
    sorted = @app.build_sorted_records(@random_files)
    assert_equal "submetering/201401/DEM_Report_01-06-14.csv", sorted.first.filename
    assert_equal "submetering/201401/DEM_Report_01-06-15.csv", sorted.last.filename
  end

  def test_previous_timestamp
    expected_tstamp = Time.parse '2015-05-15 23:45:00'
    curr_tstamp = Time.parse '2015-05-16 00:00:00'
    assert_equal expected_tstamp, @app.previous_timestamp(curr_tstamp)
  end
end
