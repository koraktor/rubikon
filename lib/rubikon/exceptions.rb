# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

module Rubikon

  class ArgumentTypeError < ArgumentError
  end

  class BlockMissingError < ArgumentError
  end

  class MissingArgumentError < ArgumentError
  end

  class MissingOptionError < ArgumentError
  end

  class UnknownOptionError < ArgumentError

    def initialize(arg)
      super "Unknown argument: #{arg}"
    end

  end

end
