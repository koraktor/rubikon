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

    include HasArguments

    attr_accessor :description
    attr_reader   :args, :params
    alias_method  :arguments, :args
    alias_method  :parameters, :params

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # @param [Application::Base] app The application this command belongs to
    # @param [Symbol, #to_sym] name The name of this command, used in application
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
      super

      @params = {}

      if block_given?
        @block = block
      else
        @file_name = "#{@app.path}/commands/#{name}.rb"
        raise BlockMissingError unless File.exists?(@file_name)
        code = open(@file_name).read
        @block = Proc.new { @app.sandbox.instance_eval(code) }
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
            @params[name] = parameter
          end
        end
        @params[parameter.name] = parameter
      end
    end

    # If a parameter with the specified method name exists, a call to that
    # method will return the value of the parameter.
    #
    # @param (see ClassMethods#method_missing)
    # @see DSLMethods#params
    #
    # @example
    #   option :user, [:who]
    #   command :hello, [:mood] do
    #     puts "Hello #{user.who}"
    #     puts "I feel #{mood}"
    #   end
    def method_missing(name, *args, &block)
      if args.empty? && !block_given? && @params.key?(name)
        @params[name]
      else
        super
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
      args.each do |arg|
        if arg.start_with?('-')
          parameter_name = arg.start_with?('--') ? arg[2..-1] : arg[1..-1]
          parameter = @params[parameter_name.to_sym]
          raise UnknownParameterError.new(arg) if parameter.nil?
        end

        unless parameter.nil?
          @app.current_param.active! unless @app.current_param.nil?
          @app.current_param = parameter
          next
        end

        if @app.current_param.nil? || !@app.current_param.more_args?
          self << arg
        else
          @app.current_param << arg
        end
      end

      @app.current_param.active! unless @app.current_param.nil?
      @app.current_param = nil
    end

    # Resets this command to its initial state
    #
    # @see HasArguments#reset
    # @since 0.4.0
    def reset
      super
      @params.values.uniq.each { |param| param.reset if param.is_a? Parameter }
    end

    # Checks whether a parameter with the given name exists for this command
    #
    # This is used to determine if a method call would successfully return the
    # value of a parameter.
    #
    # @return +true+ if named parameter with the specified name exists
    # @see #method_missing
    def respond_to_missing?(name, include_private = false)
      @params.key?(name) || super
    end

    # Run this command's code block
    #
    # @param [Array<String>] args The arguments that have been passed to this
    #        command
    def run(*args)
      parse_arguments(args)
      check_args
      @app.sandbox.instance_eval(&@block)
    end

  end

end
