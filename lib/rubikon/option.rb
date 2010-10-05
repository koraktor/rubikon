# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/has_arguments'
require 'rubikon/parameter'

module Rubikon

  # An option is an application parameter that may have one or more additional
  # arguments.
  #
  # @author Sebastian Staudt
  # @see Application::InstanceMethods#option
  # @see Parameter
  # @since 0.3.0
  class Option

    include HasArguments
    include Parameter

    # Creates a new option with the given name and an optional code block
    #
    # @param [Symbol, #to_sym] name The name of the option
    # @param [Numeric] arg_count The number of arguments this option takes.
    #        If you need a parameter that does not allow arguments at all you
    #        should use a flag instead.
    # @param [Proc] block An optional code block to be executed if this
    #        option is used
    # @see HasArguments#arg_count=
    def initialize(app, name, arg_count = 0, &block)
      super(app, name, &block)

      @args          = []
      self.arg_count = arg_count
    end

  end

end
