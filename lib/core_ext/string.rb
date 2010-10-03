# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

unless String.method_defined?(:start_with?)

  # Extends Ruby's own String class with method #start_with? for Ruby < 1.8.7
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class String

    # Returns true if this string starts with the given substring
    #
    # @param [String] start The substring to check
    # @return [Boolean] +true+ if this String starts with the given substring
    def start_with?(start)
      !/^#{start}/.match(self).nil?
    end

  end

end
