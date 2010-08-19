# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/application/base'
require 'rubikon/exceptions'

module Rubikon

  # Instances of the Command class are used to define the real code that
  # should be executed when running the Application.
  class Command

    attr_accessor :description
    attr_reader   :aliases, :name

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # +app+::   A reference to the Application instance this command belongs to
    # +name+::  The name of this command, used in Application options
    # +block+:: The code block which should be executed by this command
    def initialize(app, name, &block)
      raise ArgumentError unless app.is_a? Application::Base
      raise BlockMissingError unless block_given?

      @aliases = []
      @app     = app
      @block   = block
      @name    = name
    end

    # This is used for convinience. Relay any missing methods to this command's
    # Application instance.
    #
    # +method_name+:: The name of the method being called
    # +args+::        Any arguments that are given to the method
    # +block+::       A block that may be given to the method
    #
    # <em>This is called automatically when calling undefined methods inside
    # the command's block.</em>
    def method_missing(method_name, *args, &block)
      @app.send(method_name, *args, &block)
    end

    # Run this command's code block
    def run
      @block.call
    end

  end

end
