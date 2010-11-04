# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

module Rubikon

  # Raised by commands if no block is given and no corresponding command file
  # exists
  #
  # @author Sebastian Staudt
  # @see Command
  # @since 0.1.0
  class BlockMissingError < ArgumentError
  end

  # Raised by parameters that have been supplied with more arguments than they
  # take
  #
  # @author Sebastian Staudt
  # @see Parameter
  # @see 0.3.0
  class ExtraArgumentError < ArgumentError

    def initialize(parameter)
      super "Parameter #{parameter} has one or more extra arguments."
    end

  end

  # Raised by parameters that have been supplied with not all required
  # arguments
  #
  # @author Sebastian Staudt
  # @see Parameter
  # @since 0.1.0
  class MissingArgumentError < ArgumentError

    def initialize(parameter)
      super "Parameter #{parameter} is missing one or more arguments."
    end

  end

  # Raised if the user did not specify a command and no default command exists
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class NoDefaultCommandError < ArgumentError

    def initialize
      super 'You did not specify a command and there is no default command.'
    end

  end

  # Raised if a command has been supplied that does not exist
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class UnknownCommandError < ArgumentError

    def initialize(name)
      super "Unknown command: #{name}"
    end

  end

  # Raised if a parameter has been supplied that does not exist
  #
  # @author Sebastian Staudt
  # @since 0.3.0
  class UnknownParameterError < ArgumentError

    def initialize(name)
      super "Unknown parameter: #{name}"
    end

  end

  # Raised if a command has been supplied that does not exist
  #
  # @author Sebastian Staudt
  # @since 0.5.0
  class UnsupportedConfigFormatError < ArgumentError

    def initialize(ext)
      super "Unknown config file extension: #{ext}"
    end

  end

end
