# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/has_arguments'

module Rubikon

  # An option is an application parameter that may have one or more additional
  # arguments.
  #
  # @author Sebastian Staudt
  # @see Application::DSLMethods#option
  # @see Application::DSLMethods#global_option
  # @see Parameter
  # @since 0.3.0
  class Option

    include HasArguments

  end

end
