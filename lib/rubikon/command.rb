# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/application/base'
require 'rubikon/exceptions'
require 'rubikon/has_arguments'
require 'rubikon/parameter'

module Rubikon

  # Instances of the Command class are used to define the real code that should
  # be executed when running the Application.
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class Command

    include Parameter
    include HasArguments

    attr_accessor :description
    attr_reader   :args, :params
    alias_method  :arguments, :args
    alias_method  :parameters, :params

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # @param [Application::Sandbox] app A reference to the sandboxed
    #        application this command belongs to
    # @param [#to_sym] name The name of this command, used in application
    #        arguments
    # @param [Range, Array, Numeric] arg_count The number of arguments this
    #        command takes.
    # @param [Proc] block The code block which should be executed by this
    #        command
    # @raise [ArgumentError] if the given application object isn't a Rubikon
    #        application
    # @raise [BlockMissingError] if no command code block is given and a
    #        command file does not exist
    # @see HasArguments#arg_count=
    def initialize(app, name, arg_count = nil, &block)
      raise ArgumentError unless app.is_a? Application::Sandbox
      super(name, &block)

      @app       = app
      @args      = []
      @params    = {}

      self.arg_count = arg_count

      if block_given?
        @block = block
      else
        @file_name = "#{@app.path}/commands/#{name}.rb"
        raise BlockMissingError unless File.exists?(@file_name)
        code = open(@file_name).read
        @block = Proc.new { @app.instance_eval(code) }
      end
    end

    # Add a new parameter for this command
    #
    # @param [Parameter, Hash] parameter The parameter to add to this
    #        command. This might also be a Hash where every key will be an
    #        alias to the corresponding value, e.g. <tt>{ :alias => :parameter
    #        }</tt>.
    # @see Parameter
    def add_param(parameter)
      if parameter.is_a? Hash
        parameter.each do |alias_name, name|
          alias_name = alias_name.to_sym
          name = name.to_sym
          parameter = @params[name]
          if parameter.nil?
            @params[alias_name] = name
          else
            parameter.aliases << alias_name
            @params[alias_name] = parameter
          end
        end
      else
        raise ArgumentError unless parameter.is_a? Parameter
        @params.each do |name, param|
          if param == parameter.name
            parameter.aliases << name
          end
        end
        @params[parameter.name] = parameter
      end
    end

    # Parses the arguments of this command and sets each Parameter as active
    # if it has been supplied by the user on the command-line. Additional
    # arguments are passed to the individual parameters.
    #
    # @param [Array<String>] args The arguments that have been passed to this
    #        command
    # @raise [UnknownParameterError] if an undefined parameter is passed to the
    #        command
    # @see Flag
    # @see Option
    def parse_arguments(args)
      @args = []
      parameter = nil
      args.each do |arg|
        if arg.start_with?('-')
          parameter_name = arg.start_with?('--') ? arg[2..-1] : arg[1..-1]
          parameter = @params[parameter_name.to_sym]
          raise UnknownParameterError.new(arg) if parameter.nil?
        end

        unless parameter.nil? || parameter.active?
          parameter.active!
          next
        end

        if parameter.nil? || !parameter.more_args?
          self << arg
        else
          parameter << arg
        end
      end

      @params.values.each do |param|
        param.check_args if param.is_a?(Option) && param.active?
      end
    end

    # Run this command's code block
    #
    # @param [Array<String>] args The arguments that have been passed to this
    #        command
    def run(*args)
      parse_arguments(args)
      @app.instance_eval(&@block)
    end

  end

end
