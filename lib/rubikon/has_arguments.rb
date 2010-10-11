# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  # This module is included in all classes used for parsing command-line
  # arguments
  #
  # @author Sebastian Staudt
  # @see Application::InstanceMethods
  # @see Command
  # @see Option
  # @since 0.4.0
  module HasArguments

    # @return [Array<String>] The arguments given to this parameter
    attr_reader :args
    alias_method :arguments, :args

    # Adds an argument to this object. Arguments can be accessed inside the
    # application code using the args method.
    #
    # @param [String] arg The argument to add to the supplied arguments of this
    #        parameter
    # @raise [ExtraArgumentError] if the parameter has all required arguments
    #        supplied and does not take optional arguments
    # @return [Array] The supplied arguments of this object
    # @see #args
    # @since 0.3.0
    def <<(arg)
      if args_full? && @args.size == @max_arg_count
        raise ExtraArgumentError.new(@name)
      end
      @args << arg
    end

    # Set the allowed range of argument counts this object takes. Additionally
    # arguments may be named.
    #
    # @param [Fixnum, Range, Array] arg_count A range or array allows any
    #        number of arguments inside the limits between the first and the
    #        last element of the range or array (-1 stands for an arbitrary
    #        number of arguments). A positive number indicates the exact amount
    #        of required arguments while a negative argument count indicates
    #        the amount of required arguments, but allows additional, optional
    #        arguments. A argument count of 0 means there are no required
    #        arguments, but it allows optional arguments.
    #        Finally an array of symbols enables named arguments where the
    #        argument count is the size of the array and each argument is named
    #        after the corresponding symbol.
    # @see #args
    def arg_count=(arg_count)
      @arg_names = nil
      if arg_count.is_a? Fixnum
        if arg_count > 0
          @min_arg_count = arg_count
          @max_arg_count = arg_count
        elsif arg_count <= 0
          @min_arg_count = -arg_count
          @max_arg_count = -1
        end
      elsif arg_count.is_a?(Array) && arg_count.all? { |a| a.is_a? Symbol }
        @max_arg_count = @min_arg_count = arg_count.size
        @arg_names = arg_count
      elsif arg_count.is_a?(Range) || arg_count.is_a?(Array)
        @min_arg_count = arg_count.first
        @max_arg_count = arg_count.last
      else
        @min_arg_count = 0
        @max_arg_count = 0
      end
    end

    # Return the allowed range of argument counts this object takes
    #
    # @return [Range] The allowed range of argument counts this object takes
    def arg_count
      @min_arg_count..@max_arg_count
    end

    # Checks whether this object has all required arguments supplied
    #
    # @return +true+ if all required object arguments have been supplied
    # @since 0.3.0
    def args_full?
      @args.size >= @min_arg_count
    end

    # Checks the arguments for this object
    #
    # @raise [MissingArgumentError] if there are not enough arguments for
    #        this object
    # @since 0.3.0
    def check_args
      raise MissingArgumentError.new(@name) unless args_full?
    end

    # Checks whether this object can take more arguments
    #
    # @return +true+ if this object can take more arguments
    # @since 0.3.0
    def more_args?
      @max_arg_count == -1 || @args.size < @max_arg_count
    end

  end

end
