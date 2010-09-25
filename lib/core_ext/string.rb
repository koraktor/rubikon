# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

unless String.method_defined?(:start_with?)

  class String

    def start_with?(start)
      !/^#{start}/.match(self).nil?
    end

  end

end
