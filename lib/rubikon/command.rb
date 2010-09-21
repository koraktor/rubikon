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
    attr_reader   :arguments, :parameters

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # +app+::   A reference to the Application instance this command belongs to
    # +name+::  The name of this command, used in Application options
    # +block+:: The code block which should be executed by this command
    def initialize(app, name, &block)
      super(name, nil)

      raise ArgumentError unless app.is_a? Application::Base

      @app              = app
      @long_parameters  = {}
      @parameters       = {}
      @short_parameters = {}

      if block_given?
        @block = block
      else
        @file_name = "#{@app.path}/commands/#{name}.rb"
        raise BlockMissingError unless File.exists?(@file_name)
        code = open(@file_name).read
        @block = Proc.new { instance_eval(code) }
      end
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
    # if it has been supplied by the user on the command-line. Additional
    # arguments are passed to the individual parameters.
    #
    # +args+:: The arguments that have been passed to this command
    def parse_arguments(args)
      @arguments = []
      parameter = nil
      args.each do |arg|
        if arg.start_with?('--')
          parameter_name = @long_parameters[arg[2..-1].to_sym]
          raise UnknownParameterError.new(arg) if parameter_name.nil?
        elsif arg.start_with?('-')
          parameter_name = @short_parameters[arg[1..-1].to_sym]
          raise UnknownParameterError.new(arg) if parameter_name.nil?
        else
          parameter_name = nil
        end

        unless parameter_name.nil?
          parameter = @parameters[parameter_name]
          parameter.active!
          next
        end

        if parameter.nil? || parameter.args_full?
          @arguments << arg
        else
          parameter << arg
        end
      end

      @parameters.values.each do |param|
        param.check_args if param.is_a?(Option) && param.active?
      end
    end

    # Run this command's code block
    #
    # +args+:: The arguments that have been passed to this command
    def run(*args)
      parse_arguments(args)
      @app.instance_eval &@block
    end

  end

end
