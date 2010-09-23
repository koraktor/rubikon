# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

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

    # @return [Numeric] The number of arguments this parameter takes
    attr_reader :arg_count

    # @return [Array<String>] The arguments given to this parameter
    attr_reader :args
    alias_method :arguments, :args

    include Parameter

  end

end
