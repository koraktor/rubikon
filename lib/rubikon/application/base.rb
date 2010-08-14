# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'singleton'
require 'yaml'

require 'rubikon/action'
require 'rubikon/application/class_methods'
require 'rubikon/application/instance_methods'
require 'rubikon/exceptions'

module Rubikon

  version = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', '..', 'VERSION.yml'))
  VERSION = "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"

  module Application

    # The main class of Rubikon. Let your own application class inherit from this
    # one.
    class Base

      class << self
        include Rubikon::Application::ClassMethods
      end

      include Rubikon::Application::InstanceMethods
      include Singleton

    end

  end

end
