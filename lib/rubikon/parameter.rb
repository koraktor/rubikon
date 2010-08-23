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
    # +name+:: The name of the parameter
    def initialize(name)
      @active  = false
      @aliases = []
      @name    = name.to_sym
    end

    # Marks this parameter as active when it has been supplied by the user on
    # the command-line
    def active!
      @active = true
    end

    # Returns whether this parameter has is active, i.e. it has been supplied
    # by the user on the command-line
    def active?
      @active
    end

  end

end
