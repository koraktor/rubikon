# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rubikon/application/class_methods'
require 'rubikon/application/dsl_methods'
require 'rubikon/application/instance_methods'

module Rubikon

  # The Application module contains all basic functionality of a Rubikon
  # application
  #
  # @author Sebastian Staudt
  # @since 0.2.0
  module Application

    # The main class of Rubikon. Let your own application class inherit from
    # this one.
    #
    # @author Sebastian Staudt
    # @since 0.2.0
    class Base

      extend ClassMethods

      include DSLMethods
      include InstanceMethods

    end

  end

end
