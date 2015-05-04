#!/usr/bin/env ruby

require_relative 'lib/matrix_formatter'

converter = CsvConverter.new
presult = converter.process(ARGF)
consolidated = converter.consolidate_consumption(presult)
stripped = converter.strip_channels(consolidated, "CONSUMPTN HI", "CONSUMPTN LO")

formatter = MatrixFormatter.new
formatter.output(STDOUT, stripped)
