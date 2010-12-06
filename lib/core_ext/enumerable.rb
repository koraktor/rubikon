# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

unless Enumerable.method_defined?(:max_by)

  # Extends Ruby's own Enumrable module with method #max_by? for Ruby < 1.8.7
  #
  # @author Sebastian Staudt
  # @since 0.6.0
  module Enumerable

    # Returns the object in enum that gives the maximum value from the given
    # block.
    #
    # @yield [obj] The block to call on each element in the enum
    # @yieldparam [Object] obj A single object in the enum
    # @yieldreturn [Comparable] A value that can be compared (+<=>+) with the
    #              values of the other objects in the enum
    def max_by(&block)
      max { |a , b| block.call(a) <=> block.call(b) }
    end

  end

end
