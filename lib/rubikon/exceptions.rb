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
  # @see Application::DSLMethods#default
  # @since 0.3.0
  class NoDefaultCommandError < ArgumentError

    def initialize
      super 'You did not specify a command and there is no default command.'
    end

  end

  # Raised if a command has been supplied that does not exist
  #
  # @author Sebastian Staudt
  # @see Application::DSLMethods#command
  # @since 0.3.0
  class UnknownCommandError < ArgumentError

    # @return [Symbol] The name of the command that has been tried to access
    attr_reader :command

    # Creates a new error and stores the name of the command that could not be
    # found
    #
    # @param [Symbol] name The name of the unknown command
    def initialize(name)
      super "Unknown command: #{name}"
      @command = name
    end

  end

  # Raised if an argument is passed, that does not match a validation rule
  #
  # @author Sebastian Staudt
  # @see HasArguments#check_args
  # @since 0.6.0
  class UnexpectedArgumentError < ArgumentError

    # Creates a new error and stores the given argument value
    #
    # @param [Symbol] arg The given argument value
    def initialize(arg)
      super "Unexpected argument: #{arg}"
    end

  end

  # Raised if a parameter has been supplied that does not exist
  #
  # @author Sebastian Staudt
  # @see Application::DSLMethods#flag
  # @see Application::DSLMethods#option
  # @see Application::DSLMethods#global_flag
  # @see Application::DSLMethods#global_option
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
