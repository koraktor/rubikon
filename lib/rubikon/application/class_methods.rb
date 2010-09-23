# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

module Rubikon

  module Application

    # This module contains all class methods of +Application::Base+ and its
    # subclasses.
    #
    # @author Sebastian Staudt
    # @see Application::Base
    # @since 0.2.0
    module ClassMethods

      private

      # Returns whether this application should be run automatically
      def autorun?
        instance.instance_variable_get(:@settings)[:autorun] || false
      end

      # Enables autorun functionality using <tt>Kernel#at_exit</tt>
      #
      # <em>This is called automatically when subclassing
      # Application::Base.</em>
      #
      # @param [Class] subclass The subclass inheriting from Application::Base.
      #        This is the user's application.
      def inherited(subclass)
        super
        Singleton.__init__(subclass)
        at_exit { subclass.run if subclass.send(:autorun?) }
      end

      # This is used for convinience. Method calls on the class itself are
      # relayed to the singleton instance.
      #
      # <em>This is called automatically when calling methods on the
      # application class.</em>
      #
      # @param [Symbol] method_name The name of the method being called
      # @param [Array] args Any arguments that are given to the method
      # @param [Proc] block A block that may be given to the method
      def method_missing(method_name, *args, &block)
        instance.send(method_name, *args, &block)
      end

    end

  end

end
