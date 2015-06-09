#!/usr/bin/env ruby

require 'java'
java_import java.lang.Runtime
java_import java.io.StringWriter
java_import java.io.PrintWriter
java_import java.io.BufferedReader
java_import java.io.InputStreamReader
java_import java.io.InputStream

class ProcessWrapper
  def initialize(exit_code, output_string, error_string)
    @exit_code = exit_code
    @output_string = output_string
    @error_string = error_string
  end
  attr_accessor :exit_code, :output_string, :error_string

  def self.execute(command, args)
    process = Runtime.runtime.exec([command].concat(args).to_java(:string))

    out_string = StringWriter.new
    stdout_pump = StreamPump.new(process.input_stream, PrintWriter.new(out_string, true))

    err_string = StringWriter.new
    stderr_pump = StreamPump.new(process.error_stream, PrintWriter.new(err_string, true))

    stdout_pump.start
    stderr_pump.start
    exit_code = process.wait_for
    stdout_pump.join
    stderr_pump.join

    ProcessWrapper.new(exit_code, out_string.to_string, err_string.to_string)
  end

  class StreamPump < java.lang.Thread
    def initialize(input_stream, writer)
      @input_stream = input_stream
      @writer = writer

      super()
    end
    attr_reader :string_writer

    def run
      begin
        reader = BufferedReader.new(InputStreamReader.new(@input_stream))
        while line = reader.read_line
          @writer.println(line)
        end
      ensure
        if reader
          reader.close
        end
      end
    end
  end
end