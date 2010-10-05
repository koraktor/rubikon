# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  # A parameter is any command-line argument given to the application that is
  # not prefixed with one or two dashes. Once a parameter is supplied by the
  # user, it is relayed to the command it belongs to.
  #
  # @author Sebastian Staudt
  # @see Command
  # @since 0.3.0
  module Parameter

    # @return [Array<Symbol>] The alias names of this parameter
    attr_reader :aliases

    # @return [Symbol] The primary name of this parameter
    attr_reader :name
    # Creates a new parameter with the given name
    #
    # @param [Symbol, #to_sym] name The name of the parameter
    # @param [Proc] block An optional code block to be executed if this
    #        parameter is used
    def initialize(app, name, &block)
      raise ArgumentError unless app.is_a? Application::Sandbox

      @active  = false
      @aliases = []
      @app     = app
      @block   = block
      @name    = name.to_sym
    end

    # Marks this parameter as active when it has been supplied by the user on
    # the command-line. This also calls the code block of the parameter if it
    # exists
    def active!
      @active = true
      @app.instance_eval(&@block) unless @block.nil?
    end

    # Returns whether this parameter has is active, i.e. it has been supplied
    # by the user on the command-line
    #
    # @return +true+ if this parameter has been supplied on the command-line
    def active?
      @active
    end

  end

end
