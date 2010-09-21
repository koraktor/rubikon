# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

module Rubikon

  module Application

    module ClassMethods

      private

      # Returns whether this application should be ran automatically
      def autorun?
        instance.instance_variable_get(:@settings)[:autorun] || false
      end

      # Enables autorun functionality using <tt>Kernel#at_exit</tt>
      #
      # +subclass+:: The subclass inheriting from Application. This is the user's
      #              application.
      #
      # <em>This is called automatically when subclassing Application.</em>
      def inherited(subclass)
        super
        Singleton.__init__(subclass)
        at_exit { subclass.run if subclass.send(:autorun?) }
      end

      # This is used for convinience. Method calls on the class itself are
      # relayed to the singleton instance.
      #
      # +method_name+:: The name of the method being called
      # +args+::        Any arguments that are given to the method
      # +block+::       A block that may be given to the method
      #
      # <em>This is called automatically when calling methods on the class.</em>
      def method_missing(method_name, *args, &block)
        instance.send(method_name, *args, &block)
      end

    end

  end

end
