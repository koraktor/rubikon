# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt
# Copyright (c) 2010, Dotan J. Nahum

module Rubikon

  # A class for displaying and managing progress bars
  #
  # @author Sebastian Staudt
  # @see Application::InstanceMethods#throbber
  # @since 0.2.0
  class ProgressBar

    # Create a new ProgressBar using the given options.
    #
    # @param [Hash, Numeric] options A Hash of options to customize the
    #        progress bar or the maximum value of the progress bar
    # @see Application::InstanceMethods#progress_bar
    #
    # @option options [String] :char ('#') The character used for progress bar
    #         display
    # @option options [Numeric] :maximum (100) The maximum value of this
    #         progress bar
    # @option options [IO] :ostream ($stdout) The output stream where the
    #         progress bar should be displayed
    # @option options [Numeric] :size (20) The actual size of the progress bar
    # @option options [Numeric] :start (0) The start value of the progress bar
    def initialize(options = {})
      if options.is_a? Numeric
        @maximum = options
        options = {}
      else
        @maximum = options[:maximum] || 100
      end
      @maximum.round

      @progress_char  = options[:char] || '#'
      @ostream        = options[:ostream] || $stdout
      @progress       = 0
      @size           = options[:size] || 20
      @factor         = @size.round.to_f / @maximum
      @value          = 0
      @brackets       = options[:brackets] || false
      @bracket_filler = options[:bracket_filler] || ' '

      if @brackets
        @ostream << '[' + @bracket_filler * @size + ']'+ "\b" * (@size + 1)
        @ostream.flush
      end
      self + (options[:start] || 0)
    end

    # Add an amount to the current value of the progress bar
    #
    # This triggers a refresh of the progress bar, if the added value actually
    # changes the displayed bar.
    #
    # @param [Numeric] value The amount to add to the progress bar
    # @return [ProgressBar] The progress bar itself
    #
    # @example Different alternatives to increase the progress
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
        @ostream.putc 10 if @progress == @size
      end

      self
    end

  end

end
