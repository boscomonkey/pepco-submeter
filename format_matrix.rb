#!/usr/bin/env ruby

require_relative 'lib/matrix_formatter'

converter = CsvConverter.new
presult = converter.process(ARGF)

formatter = MatrixFormatter.new
formatter.output(STDOUT, presult)
