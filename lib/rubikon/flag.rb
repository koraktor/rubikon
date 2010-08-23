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
      super(name)

      @block = block
    end

    # Marks this flag as active when it has been supplied by the user on the
    # command-line. This also calls the code block of the flag if it exists
    def active!
      super

      @block.call unless @block.nil?
    end

  end

end
