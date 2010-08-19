# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

module Rubikon

  class BlockMissingError < ArgumentError
  end

  class NoDefaultCommandError < ArgumentError

    def initialize
      super 'You did not specify a command and there is no default command.'
    end

  end

  class UnknownCommandError < ArgumentError

    def initialize(name)
      super "Unknown command: #{name}"
    end

  end

  class UnknownParameterError < ArgumentError

    def initialize(name)
      super "Unknown parameter: #{name}"
    end

  end

end
