# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  # A parameter is any command-line argument given to the application that is
  # not prefixed with one or two dashes. Once a parameter is supplied by the
  # user, it is relayed to the Command it belongs to.
  module Parameter

    attr_reader :aliases, :name

    # Creates a new parameter with the given name
    #
    # +name+::      The name of the parameter
    # +arg_count+:: The number of arguments this parameter takes if any for
    #               this parameter if any
    # +block+::     An optional code block to be executed if this parameter is
    #               used
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
    def <<(arg)
      if @args.size < @arg_count || @arg_count < 0
        @args << arg
      else
        raise ExtraArgumentError.new(@name)
      end
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
    def active?
      @active
    end

  end

end
