# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

module Rubikon

  # Instances of the Action class are used to define the real code that should
  # be executed when running the application.
  class Action

    attr_reader :block, :description, :name, :param_type

    # Create a new Action using the given name, options and code block.
    #
    # +name+::    The name of this Action, used in Application options
    # +options+:: A Hash of options that define more details about the Action
    # +block+::   The code block which should be executed by this Action
    #
    # Options:
    # +description+:: A description of the action. This isn't used at the
    #                 moment.
    # +param_type+::  A single Class or a Array of classes that represent the
    #                 type(s) of argument(s) this action expects
    def initialize(options = {}, &block)
      raise BlockMissingError unless block_given?

      @description = options[:description] || ''
      @param_type = options[:param_type] || Object

      @block = block
      @arg_count = block.arity
    end

    # Run this action's code block
    #
    # +args+:: The argument which should be relayed to the block of this Action
    def run(*args)
      raise MissingArgumentError unless check_argument_count(args.size)
      raise Rubikon::ArgumentTypeError unless check_argument_types(args)
      @block[*args]
    end

    private

    # Checks if the number of arguments given fits the number of arguments of
    # this Action
    #
    # +count+:: The number of arguments
    def check_argument_count(count)
      !((@arg_count >= 0 && count < @arg_count) || (@arg_count < 0 && count < -@arg_count - 1))
    end

    # Checks the types of the given arguments using the Class or Array of
    # classes given in the +:param_type+ option of this action.
    #
    # +args+:: The arguments which should be checked
    def check_argument_types(args)
      if @param_type.is_a? Array
        args.each_index do |arg_index|
          return false unless args[arg_index].is_a? @param_type[arg_index]
        end
      else
        args.each do |arg|
          return false unless arg.is_a? @param_type
        end
      end

      true
    end

  end

end
