# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  # A parameter is any command-line argument given to the application that is
  # not a Command. Instead parameters are relayed to commands.
  module Parameter

    attr_reader :aliases, :name

    # Creates a new parameter with the given name
    #
    # +name+::  The name of the parameter
    # +block+:: An optional code block to be executed if this parameter is used
    def initialize(name, &block)
      @active  = false
      @aliases = []
      @block   = block
      @name    = name.to_sym
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
