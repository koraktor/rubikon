# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2011, Sebastian Staudt

module Rubikon

  # A class for displaying and managing throbbers
  #
  # @author Sebastian Staudt
  # @see Application::DSLMethods#throbber
  # @since 0.2.0
  class Throbber < Thread

    # Creates and runs a Throbber that outputs to the given IO stream while the
    # given thread is alive
    #
    # @param [IO] ostream the IO stream the throbber should be written to
    # @param [Thread] thread The thread that should be watched
    # @param [Hash] options Options to customize this throbber instance
    # @option options [Float] delay The delay inbetween printing single steps
    #         of the throbber (default: 0.25)
    # @option options [String] spinner The characters that should be used to
    #         display the throbber (default: '-\|/')
    # @see Application::InstanceMethods#throbber
    def initialize(ostream, thread, options = {})
      options = {
        :delay => 0.25,
        :spinner => '-\|/'
      }.merge options

      proc = Proc.new do |os, thr|
          step = 0
          os.putc 32
          while thr.alive?
            os << "\b#{options[:spinner][step].chr}"
            os.flush
            step = (step + 1) % 4
            sleep options[:delay]
          end
        os.putc 8
      end

      super { proc.call(ostream, thread) }
    end

  end

end
