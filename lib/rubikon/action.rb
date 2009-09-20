# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

module Rubikon

  class Action

    @@action_count = 0

    attr_reader :block, :description, :name, :param_type

    def initialize(name, options, block)
      @name = name

      options ||= {}

      @description = options[:description] || ''
      @param_type = options[:param_type] || Object

      @block = block
    end

    # Run this action's code block
    def run(*args)
      raise MissingArgument if args.size != @block.arity
      raise TypeError unless check_args(args)
      @block[*args]
    end

    private

    def check_args(args)
      args.each do |arg|
        return false unless arg.is_a? @param_type
      end
    end

  end

end
