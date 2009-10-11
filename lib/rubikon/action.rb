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
      if (@block.arity >= 0 and args.size < @block.arity) or (@block.arity < 0 and args.size < -@block.arity - 1)
        raise MissingArgumentError
      end
      raise TypeError unless check_argument_types(args)
      @block[*args]
    end

    private

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
    end

  end

end
