# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/parameter'

module Rubikon

  # A flag is an Application Parameter without arguments
  class Flag

    include Parameter

    # Creates a new flag with the given name and an optional code block
    #
    # +name+::  The name of the flag
    # +block+:: An optional code block to be executed if this flag is used
    def initialize(name, &block)
      super(name, 0, &block)
    end

    # Adds an argument to this flag
    #
    # This always raises an ExtraArgumentError because flags never take any
    # arguments.
    def <<(arg)
      raise ExtraArgumentError.new(@name)
    end

    # Checks whether this flag has all required arguments supplied
    #
    # This is always true because flags never take any arguments.
    def args_full?
      true
    end

  end

end
