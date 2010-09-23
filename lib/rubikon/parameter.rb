# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  # A parameter is any command-line argument given to the application that is
  # not prefixed with one or two dashes. Once a parameter is supplied by the
  # user, it is relayed to the Command it belongs to.
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  module Parameter

    # @return [Array<Symbol>] The alias names of this parameter
    attr_reader :aliases

    # @return [Symbol] The primary name of this parameter
    attr_reader :name

    # Creates a new parameter with the given name
    #
    # @param [Symbol, #to_sym] name The name of the parameter
    # @param [Numeric] arg_count The number of arguments this parameter takes
    #        if any
    # @param [Proc] block An optional code block to be executed if this
    #        parameter is used
    #
    # A positive argument count indicates the exact amount of required
    # arguments, while a negative argument count indicates the amount of
    # required arguments, but allows additional, optional arguments. A argument
    # count of 0 means there are no required arguments, but it allows optional
    # arguments. If you need a parameter that does not allow arguments at all
    # you should use a Flag instead.
    def initialize(name, arg_count = 0, &block)
      @active    = false
      @aliases   = []
      @arg_count = arg_count
      @args      = []
      @block     = block
      @name      = name.to_sym
    end

    # Adds an argument to this parameter. Parameter arguments can be accessed
    # inside the Application code using the parameter's args method.
    #
    # @param [String] arg The argument to add to the supplied arguments of this
    #        parameter
    # @raise [ExtraArgumentError] if the parameter has all required arguments
    #        supplied and does not take optional arguments
    # @return [Array] The supplied arguments of this parameter
    def <<(arg)
      raise ExtraArgumentError.new(@name) if args_full? && @arg_count > 0
      @args << arg
    end

    # Marks this parameter as active when it has been supplied by the user on
    # the command-line. This also calls the code block of the parameter if it
    # exists
    def active!
      @active = true
      @block.call unless @block.nil?
    end

    # Returns whether this parameter has is active, i.e. it has been supplied
    # by the user on the command-line
    #
    # @return +true+ if this parameter has been supplied on the command-line
    def active?
      @active
    end

    # Checks whether this parameter has all required arguments supplied
    #
    # @return +true+ if all required parameter arguments have been supplied
    def args_full?
      arg_count = @arg_count
      arg_count = -arg_count if arg_count < 0

      arg_count == 0 || @args.size >= arg_count
    end

    # Checks the arguments for this parameter
    #
    # @raise [MissingArgumentError] if there are not enough arguments for
    #                               this parameter.
    def check_args
      raise MissingArgumentError.new(@name) unless args_full?
    end

    # Checks whether this parameter can take more arguments
    #
    # @return +true+ if this parameter can take more arguments
    def more_args?
      arg_count <= 0 || @args.size < arg_count
    end

  end

end
