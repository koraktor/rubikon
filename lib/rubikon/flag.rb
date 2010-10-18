# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/parameter'

module Rubikon

  # A flag is an application parameter without arguments
  #
  # @author Sebastian Staudt
  # @see Application::InstanceMethods#flag
  # @see Application::InstanceMethods#global_flag
  # @see Parameter
  # @since 0.3.0
  class Flag

    include Parameter

    private

    # Adds an argument to this flag
    #
    # @param arg (see Parameter#<<)
    # @raise [ExtraArgumentError] is raised because flags never take any
    #                             arguments.
    def <<(arg)
      raise ExtraArgumentError.new(@name)
    end

    # Checks whether this flag has all required arguments supplied
    #
    # @return [true] This is always +true+ because flags never take any
    #                arguments.
    def args_full?
      true
    end

    # Checks whether this flag can take more arguments
    #
    # @return [false] This is always +false+ because flags never take any
    #                 arguments.
    def more_args?
      false
    end

  end

end
