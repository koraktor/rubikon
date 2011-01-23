# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

require 'rubikon/parameter'

module Rubikon

  # This module is included in all classes used for parsing command-line
  # arguments
  #
  # @author Sebastian Staudt
  # @see Application::InstanceMethods
  # @see Command
  # @see Option
  # @since 0.4.0
  module HasArguments

    include Parameter

    # Provides a number of predefined regular expressions to check arguments
    # against
    #
    # @see #initialize
    # @since 0.6.0
    ARGUMENT_MATCHERS = {
      # Allow only alphanumeric characters
      :alnum   => /[[:alnum:]]+/,
      # Allow only floating point numbers as arguments
      :float   => /-?[0-9]+(?:\.[0-9]+)?/,
      # Allow only alphabetic characters
      :letters => /[a-zA-Z]+/,
      # Allow only numeric arguments
      :numeric => /-?[0-9]+/
    }

    # Creates a new parameter with arguments with the given name and an
    # optional code block
    #
    # @param [Application::Base] app The application this parameter belongs to
    # @param [Symbol, #to_sym] name The name of the parameter
    # @param [Array] options A range or array allows any number of arguments
    #        inside the limits between the first and the last element of the
    #        range or array (-1 stands for an arbitrary number of arguments). A
    #        positive number indicates the exact amount of required arguments
    #        while a negative argument count indicates the amount of required
    #        arguments, but allows additional, optional arguments. A argument
    #        count of 0 means there are no required arguments, but it allows
    #        optional arguments. Finally an array of symbols enables named
    #        arguments where the argument count is the size of the array and
    #        each argument is named
    #        after the corresponding symbol.
    # @param [Proc] block An optional code block to be executed if this
    #        option is used
    def initialize(app, name, *options, &block)
      super(app, name, &block)

      @arg_names  = []
      @arg_values = {}
      @args       = {}

      @description = options.shift if options.first.is_a? String

      if options.size == 1 && (options.first.nil? ||
         options.first.is_a?(Fixnum) || options.first.is_a?(Range))
        options = options.first
      end

      if options.is_a? Fixnum
        if options > 0
          @min_arg_count = options
          @max_arg_count = options
        elsif options <= 0
          @min_arg_count = -options
          @max_arg_count = -1
        end
      elsif options.is_a? Range
        @min_arg_count = options.first
        @max_arg_count = options.last
      elsif options.is_a? Array
        @arg_names = []
        @max_arg_count = 0
        @min_arg_count = 0
        options.each do |arg|
          if arg.is_a? Hash
            arg = arg.map do |arg_name, opt|
              [arg_name, opt.is_a?(Array) ? opt : [opt]]
            end
            arg = arg.sort_by do |arg_name, opt|
              opt.include?(:optional) ? 1 : 0
            end
            arg.each do |arg_name, opt|
              matchers = opt.reject { |o| [:optional, :remainder].include? o }
              opt -= matchers
              @arg_names << arg_name.to_sym
              if !matchers.empty?
                matchers.map! do |m|
                  ARGUMENT_MATCHERS[m] || (m.is_a?(Regexp) ? m : m.to_s)
                end
                @arg_values[arg_name] = /^#{Regexp.union *matchers}$/
              end
              unless opt.include? :optional
                @min_arg_count += 1
              end
              if opt.include? :remainder
                @max_arg_count = -1
                break
              end
              @max_arg_count += 1
            end
          else
            @arg_names << arg.to_sym
            @min_arg_count += 1
            @max_arg_count += 1
          end
        end
      else
        @min_arg_count = 0
        @max_arg_count = 0
      end
    end

    # Access the arguments of this parameter using a numeric or symbolic index
    #
    # @param [Numeric, Symbol] The index of the argument to return. Numeric
    #        indices can be used always while symbolic arguments are only
    #        available for named arguments.
    # @return The argument with the specified index
    # @see #args
    # @since 0.4.0
    def [](arg)
      @args[arg]
    end

    # Returns the arguments given to this parameter. They are given as a Hash
    # when there are named arguments or as an Array when there are no named
    # arguments
    #
    # @return [Array<String>, Hash<Symbol, String>] The arguments given to this
    #         parameter
    # @since 0.6.0
    def args
      @arg_names.empty? ? @args.values : @args
    end
    alias_method :arguments, :args

    protected

    # Adds an argument to this parameter. Arguments can be accessed inside the
    # application code using the args method.
    #
    # @param [String] arg The argument to add to the supplied arguments of this
    #        parameter
    # @raise [ExtraArgumentError] if the parameter has all required arguments
    #        supplied and does not take optional arguments
    # @return [Array] The supplied arguments of this parameter
    # @see #[]
    # @see #args
    # @since 0.3.0
    def <<(arg)
      raise ExtraArgumentError.new(@name) unless more_args?

      if @arg_names.size > @args.size
        name = @arg_names[@args.size]
        if @max_arg_count == -1 && @arg_names.size == @args.size + 1
          @args[name] = [arg]
        else
          @args[name] = arg
        end
      elsif !@arg_names.empty? && @max_arg_count == -1
        @args[@arg_names.last] << arg
      else
        @args[@args.size] = arg
      end
    end

    # Marks this parameter as active when it has been supplied by the user on
    # the command-line. This also checks the arguments given to this parameter.
    #
    # @see #check_args
    # @see Paramter#active!
    def active!
      check_args
      super
    end

    # Return the allowed range of argument counts this parameter takes
    #
    # @return [Range] The allowed range of argument counts this parameter takes
    def arg_count
      @min_arg_count..@max_arg_count
    end

    # Checks whether this parameter has all required arguments supplied
    #
    # @return +true+ if all required parameter arguments have been supplied
    # @since 0.3.0
    def args_full?
      @args.size >= @min_arg_count
    end

    # Checks the arguments for this parameter
    #
    # @raise [MissingArgumentError] if there are not enough arguments for
    #        this parameter
    # @since 0.3.0
    def check_args
      raise MissingArgumentError.new(@name) unless args_full?
      unless @arg_values.empty?
        @args.each do |name, arg|
          unless @arg_values[name].nil?
            arg = [arg] unless arg.is_a? Array
            arg.each do |a|
              unless a =~ @arg_values[name]
                raise UnexpectedArgumentError.new(a)
              end
            end
          end
        end
      end
    end

    # If a named argument with the specified method name exists, a call to that
    # method will return the value of the argument.
    #
    # @param (see ClassMethods#method_missing)
    # @see #args
    # @see #[]
    #
    # @example
    #   option :user, [:name] do
    #     @user = name
    #   end
    def method_missing(name, *args, &block)
      if args.empty? && !block_given? && @arg_names.include?(name)
        @args[name]
      else
        super
      end
    end

    # Checks whether this parameter can take more arguments
    #
    # @return +true+ if this parameter can take more arguments
    # @since 0.3.0
    def more_args?
      @max_arg_count == -1 || @args.size < @max_arg_count
    end

    # Resets this parameter to its initial state
    #
    # @see Parameter#reset
    # @since 0.4.0
    def reset
      super
      @args.clear
    end

    # Checks whether an argument with the given name exists for this parameter
    #
    # This is used to determine if a method call would successfully return the
    # value of an argument.
    #
    # @return +true+ if named argument with the specified name exists
    # @see #method_missing
    def respond_to_missing?(name, include_private = false)
      @arg_names.include? name
    end

  end

end
