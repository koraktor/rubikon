# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/application/base'
require 'rubikon/exceptions'
require 'rubikon/parameter'

module Rubikon

  # Instances of the Command class are used to define the real code that should
  # be executed when running the Application.
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class Command

    include Parameter

    attr_accessor :description
    attr_reader   :arguments, :parameters

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # @param [Application::Base] app A reference to the application 
    #        instance this command belongs to
    # @param [#to_sym] name The name of this command, used in application
    #        arguments
    # @param [Proc] block The code block which should be executed by this
    #        command
    # @raise [ArgumentError] if the given application object isn't a Rubikon
    #        application
    # @raise [BlockMissingError] if no command code block is given and a
    #        command file does not exist
    def initialize(app, name, &block)
      raise ArgumentError unless app.is_a? Application::Base
      super(name, nil)

      @app        = app
      @parameters = {}

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
    # @param [Parameter, Hash] parameter The parameter to add to this 
    #        command. This might also be a Hash where every key will be an
    #        alias to the corresponding value, e.g. <tt>{ :alias => :parameter
    #        }</tt>.
    # @see Parameter
    def <<(parameter)
      if parameter.is_a? Hash
        parameter.each do |alias_name, name|
          alias_name = alias_name.to_sym
          name = name.to_sym
          parameter = @parameters[name]
          if parameter.nil?
            @parameters[alias_name] = name
          else
            parameter.aliases << alias_name
            @parameters[alias_name] = parameter
          end
        end
      else
        raise ArgumentError unless parameter.is_a? Parameter
        @parameters.each do |name, param|
          if param == parameter.name
            parameter.aliases << name
          end
        end
        @parameters[parameter.name] = parameter
      end
    end

    # Parses the arguments of this command and sets each Parameter as active
    # if it has been supplied by the user on the command-line. Additional
    # arguments are passed to the individual parameters.
    #
    # @param [Array<String>] args The arguments that have been passed to this
    #        command
    # @raise [UnknownParameterError] if an undefined parameter is passed to the
    #        command @see Flag @see Option
    def parse_arguments(args)
      @arguments = []
      parameter = nil
      args.each do |arg|
        if arg.start_with?('-')
          parameter_name = arg.start_with?('--') ? arg[2..-1] : arg[1..-1]
          parameter = @parameters[parameter_name.to_sym]
          raise UnknownParameterError.new(arg) if parameter.nil?
        end

        unless parameter.nil? || parameter.active?
          parameter.active!
          next
        end

        if parameter.nil? || !parameter.more_args?
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
    # @param [Array<String>] args The arguments that have been passed to this
    #        command
    def run(*args)
      parse_arguments(args)
      @app.instance_eval(&@block)
    end

  end

end
