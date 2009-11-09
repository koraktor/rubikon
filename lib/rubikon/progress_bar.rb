# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

module Rubikon

  # A class for displaying and managing progress bars
  class ProgressBar

    # Create a new ProgressBar using the given options.
    #
    # +ostream+:: The output stream where the progress bar should be displayed
    # +options+:: An Hash of options to customize the progress bar
    #
    # Options:
    #
    # +char+::    The character used for progress bar display (default: +#+)
    # +maximum+:: The maximum value of this progress bar (default: +100+)
    # +size+::    The actual size of the progress bar (default: +20+)
    # +start+::   The start value of the progress bar (default: +0+)
    def initialize(options = {})
      if options.is_a? Numeric
        @maximum = options
        options = {}
      else
        @maximum = options[:maximum] || 100
      end
      @maximum.round

      @progress_char = options[:char] || '#'
      @ostream  = options[:ostream] || $stdout
      @progress = 0
      @size     = options[:size] || 20
      @factor   = @size.round.to_f / @maximum
      @value    = 0

      self + (options[:start] || 0)
    end

    # Add an amount to the current value of the progress bar
    #
    # This triggers a refresh of the progress bar, if the added value actually
    # changes the displayed bar.
    #
    # Example:
    #
    #  progress_bar + 1 # (will add 1)
    #  progress_bar + 5 # (will add 5)
    #  progress_bar.+   # (will add 1)
    def +(value = 1)
      return if (value <= 0) || (@value == @maximum)
      @value += value
      old_progress = @progress
      add_progress = ((@value - @progress / @factor) * @factor).round
      @progress += add_progress

      if @progress > @size
        @progress = @size
        add_progress = @size - old_progress
      end

      if add_progress > 0
        @ostream << @progress_char * add_progress
        @ostream.flush
        @ostream.puts '' if @progress == @size
      end
    end

  end

end
