# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

require 'rubikon/application/base'
require 'rubikon/exceptions'
require 'rubikon/has_arguments'
require 'rubikon/parameter'

module Rubikon

  # Instances of the Command class are used to define the real code that should
  # be executed when running the Application.
  #
  # @author Sebastian Staudt
  # @see Application::DSLMethods#command
  # @see Application::DSLMethods#default
  # @since 0.3.0
  class Command

    include HasArguments

    # @return [String] The description of this command
    attr_accessor :description

    # @return [Array<Parameter>] The parameters of this command
    attr_reader   :params
    alias_method  :parameters, :params

    # Create a new application command with the given name with a reference to
    # the app it belongs to
    #
    # @param [Application::Base] app The application this command belongs to
    # @param [Symbol, #to_sym] name The name of this command, used in application
    #        arguments
    # @param options (see HasArguments#initialize)
    # @param [Proc] block The code block which should be executed by this
    #        command
    # @raise [ArgumentError] if the given application object isn't a Rubikon
    #        application
    # @raise [BlockMissingError] if no command code block is given and a
    #        command file does not exist
    def initialize(app, name, *options, &block)
      super

      @params = {}

      if block_given?
        @block = block
      else
        @file_name = "#{@app.path}/commands/#{name}.rb"
        raise BlockMissingError unless File.exists?(@file_name)
        code = open(@file_name).read
        @block = Proc.new { instance_eval(code) }
      end
    end

    # Generate help for this command
    #
    # @param [Boolean] show_usage If +true+, the returned String will also
    #        include usage information
    # @return [String] The contents of the help screen for this command
    # @since 0.6.0
    def help(show_usage = true)
      help = ''

      if show_usage
        help << " #{name}" if name != :__default

        @params.values.uniq.sort_by {|a| a.name.to_s }.each do |param|
          help << ' ['
          ([param.name] + param.aliases).each_with_index do |name, index|
            name = name.to_s
            help << '|' if index > 0
            help << '-' if name.size > 1
            help << "-#{name}"
          end
          help << ' ...' if param.is_a?(Option)
          help << ']'
        end
      end

      help << "\n\n#{description}" unless description.nil?

      help_flags = {}
      help_options = {}
      params.each_value do |param|
        if param.is_a? Flag
          help_flags[param.name.to_s] = param
        else
          help_options[param.name.to_s] = param
        end
      end

      param_name = lambda { |name| "#{name.size > 1 ? '-' : ' '}-#{name}" }
      unless help_flags.empty? && help_options.empty?
        max_param_length = (help_flags.keys + help_options.keys).
          max_by { |a| a.size }.size + 2
      end

      unless help_flags.empty?
        help << "\n\nFlags:"
        help_flags.sort_by { |name, param| name }.each do |name, param|
          help << "\n  #{param_name.call(name).ljust(max_param_length)}"
          help << "      #{param.description}" unless param.description.nil?
        end
      end

      unless help_options.empty?
      help << "\n\nOptions:\n"
        help_options.sort_by { |name, param| name }.each do |name, param|
          help << "  #{param_name.call(name).ljust(max_param_length)} ..."
          help << "  #{param.description}" unless param.description.nil?
          help << "\n"
        end
      end

      help
    end

    private

    # Returns all parameters of this command that are active, i.e. that have
    # been supplied on the command-line
    #
    # @return [Array<Parameter>] All currently active parameters of this
    #         command
    # @since 0.6.0
    def active_params
      @params.values.select { |param| param.active? }
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
    #
    # @example
    #   option :user, [:who]
    #   command :hello, [:mood] do
    #     puts "Hello #{user.who}"
    #     puts "I feel #{mood}"
    #   end
    def method_missing(name, *args, &block)
      if args.empty? && !block_given?
        if @params.key?(name)
          return @params[name]
        else
          active_params.each do |param|
            return param.send(name) if param.respond_to_missing?(name)
          end
        end
      end

      super
    end

    # Resets this command to its initial state
    #
    # @see HasArguments#reset
    # @since 0.4.0
    def reset
      super
      @params.values.uniq.each do |param|
        param.send(:reset) if param.is_a? Parameter
      end
    end

    # Checks whether a parameter with the given name exists for this command
    #
    # This is used to determine if a method call would successfully return the
    # value of a parameter.
    #
    # @return +true+ if named parameter with the specified name exists
    # @see #method_missing
    def respond_to_missing?(name, include_private = false)
      @params.key?(name) ||
      active_params.any? { |param| param.respond_to_missing?(name) } ||
      super
    end

    # Run this command's code block
    def run
      check_args
      Application::InstanceMethods.instance_method(:sandbox).bind(@app).call.
        instance_eval(&@block)
    end

  end

end
