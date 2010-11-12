# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

unless Object.method_defined?(:respond_to_missing?)

  # Extends Ruby's own Object class with method #respond_to_missing? for Ruby
  # < 1.9.2
  #
  # @author Sebastian Staudt
  # @since 0.4.0
  class Object

    # Returns +true+ if _obj_ responds to the given method. Private methods
    # are included in the search only if the optional second parameter
    # evaluates to +true+.
    #
    # If the method is not implemented, as Process.fork on Windows,
    # File.lchmod on GNU/Linux, etc., +false+ is returned.
    #
    # If the method is not defined, respond_to_missing? method is called and
    # the result is returned.
    #
    # @see #respond_to_missing?
    def respond_to?(symbol, include_private = false)
      super || respond_to_missing?(symbol, include_private)
    end

    # Hook method to return whether the _obj_ can respond to _id_ method or
    # not.
    #
    # @param [Symbol] symbol The id of the method to check
    # @return [Boolean] +true+ if this object responds to this method via
    #         via method_missing
    # @see #method_missing
    # @see #respond_to?
    def respond_to_missing?(symbol, include_private = false)
      false
    end

  end

end
