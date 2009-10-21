# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

module Rubikon

  # Instances of the Action class are used to define the real code that should
  # be executed when running the application.
  class Action

    @@action_count = 0

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
    def initialize(name, options = {}, &block)
      raise BlockMissingError unless block_given?

      @name = name

      @description = options[:description] || ''
      @param_type = options[:param_type] || Object

      @block = block
    end

    # Run this action's code block
    #
    # +args+:: The argument which should be relayed to the block of this Action
    def run(*args)
      if (@block.arity >= 0 and args.size < @block.arity) or (@block.arity < 0 and args.size < -@block.arity - 1)
        raise MissingArgumentError
      end
      raise Rubikon::ArgumentTypeError unless check_argument_types(args)
      @block[*args]
    end

    private

    # Checks the types of the given arguments using the Class or Array of
    # classes given in the +:param_type+ option of this action.
    #
    # +args+:: The arguments which should be checked
    def check_argument_types(args)
      if @param_type.is_a? Array
        args.each_index do |i|
          return false unless args[i].is_a? @param_type[i]
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
