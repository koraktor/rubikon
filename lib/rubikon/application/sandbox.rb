# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  module Application

    # The application sandbox is a wrapper used to secure internal Rubikon
    # logic from access by user generated application code.
    #
    # This is mostly to prevent accidental execution or change of Rubikon's
    # internal code. But it also helps to prevent possible security problems
    # depending on the code used inside the application logic.
    #
    # @see Application::InstanceMethods
    # @since 0.4.0
    class Sandbox

      # Create a new application sandbox
      #
      # @param [Application::Base] app The application to be sandboxed
      def initialize(app)
        raise ArgumentError unless app.is_a? Application::Base
        @__app__ = app
      end

      # Method calls on the sandbox wrapper will be relayed to the singleton
      # instance. Methods defined in InstanceMethods are protected and will
      # raise a NoMethodError.
      #
      # @param (see ClassMethods#method_missing)
      # @raise [NoMethodError] if a method is called that is defined inside
      #        InstanceMethods and should therefore be protected
      # @see InstanceMethods
      def method_missing(name, *args, &block)
        if @__app__.class.instance_methods(false).include?(name.to_s) ||
           !(InstanceMethods.method_defined?(name) ||
           InstanceMethods.private_method_defined?(name))
          @__app__.send(name, *args, &block)
        else
          raise NoMethodError.new("Method `#{name}' is protected by the application sandbox", name)
        end
      end

      # Relay putc to the instance method
      #
      # This is used to hide <tt>Kernel#putc</tt> so that the application's
      # output IO object is used for printing characters
      #
      # @param [String, Numeric] char The character to write into the output
      #        stream
      def putc(text)
        @__app__.send(:putc, text)
      end

      # Relay puts to the instance method
      #
      # This is used to hide <tt>Kernel#puts</tt> so that the application's
      # output IO object is used for printing text
      #
      # @param [String] text The text to write into the output stream
      def puts(*text)
        @__app__.send(:puts, *text)
      end

    end

  end

end
