# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/application/base'
require 'rubikon/exceptions'
require 'rubikon/parameter'

module Rubikon

  # Instances of the Command class are used to define the real code that
  # should be executed when running the Application.
  class Command

    include Parameter

    attr_accessor :description
    attr_reader   :aliases, :parameters

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # +app+::   A reference to the Application instance this command belongs to
    # +name+::  The name of this command, used in Application options
    # +block+:: The code block which should be executed by this command
    def initialize(app, name, &block)
      super(name)

      raise ArgumentError unless app.is_a? Application::Base
      raise BlockMissingError unless block_given?

      @aliases          = []
      @app              = app
      @block            = block
      @long_parameters  = {}
      @parameters       = {}
      @short_parameters = {}
    end

    # Add a new Parameter for this command
    #
    # +parameter+:: The parameter to add to this command. This might also be a
    #               Hash where every key will be an alias to the corresponding
    #               value, e.g. <tt>{ :alias => :parameter }</tt>.
    def <<(parameter)
      if parameter.is_a? Hash
        parameter.each do |alias_name, name|
          if alias_name.size == 1
            @short_parameters[alias_name.to_sym] = name.to_sym
          else
            @long_parameters[alias_name.to_sym] = name.to_sym
          end
        end
      else
        raise ArgumentError unless parameter.is_a? Parameter
        @parameters[parameter.name] = parameter

        if parameter.name.to_s.size == 1
          @short_parameters[parameter.name] = parameter.name
        else
          @long_parameters[parameter.name] = parameter.name
        end
      end
    end

    # Parses the arguments of this command and sets each Parameter as active
    # if it has been supplied by the user on the command-line
    #
    # +args+:: The arguments that have been passed to this command
    def parse_arguments(args)
      parameter = nil
      args.each do |arg|
        if arg.start_with?('--')
          parameter = @parameters[@long_parameters[arg[2..-1].to_sym]]
        elsif arg.start_with?('-')
          parameter = @parameters[@short_parameters[arg[1..-1].to_sym]]
        end

        raise UnknownParameterError.new(arg) if parameter.nil?
        parameter.active!
      end
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
    #
    # +args+:: The arguments that have been passed to this command
    def run(*args)
      parse_arguments(args)
      @block.call
    end

  end

end
