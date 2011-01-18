# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

module Rubikon

  # This module will extend the argument array passed to the application,
  # usually ARGV. It provides functionality to parse Rubikon specific tokens
  # from the strings contained in the argument list passed to the application.
  #
  # @author Sebastian Staudt
  # @since 0.6.0
  module ArgumentVector

    # Gets the command to use from the list of arguments passed to the
    # application. The first argument matching a command name or alias will
    # cause the corresponding command to be selected.
    #
    # The command and all arguments equal to '--' will be removed from the
    # array.
    #
    # @param [Hash<Symbol, Command>] commands A list of available commands
    # @return [Command] The command found in the argument list
    # @return [Fixnum] The position of the command in the argument list
    def command!(commands)
      command = nil
      command_index = 0
      each_with_index do |arg, i|
        break if arg == '--'

        command = commands[arg.to_sym]
        unless command.nil?
          command_index = i
          delete_at i
          break
        end
      end
      delete '--'

      command ||= commands[:__default]

      return command, command_index
    end

    # Turns arguments using a special syntax into arguments that are parseable.
    #
    # Single character parameters may be joined together like '-dv'. This
    # method will split them into separate parameters like '-d -v'.
    #
    # Additionally a parameter argument may be attached to the parameter itself
    # using '=' like '--path=/tmp'. This method will also split them into
    # '--path /tmp'.
    def expand!
      each_with_index do |arg, i|
        next if !arg.start_with?('-')
        self[i] = arg.split('=', 2)
        next if arg.start_with?('--')
        self[i] = arg[1..-1].split('').uniq.map { |a| '-' + a }
      end
      flatten!
    end

    # Selects active parameters from a list of available parameters
    #
    # For every option found in the argument list {#scoped_args!} is called to
    # find the arguments for that option.
    #
    # All parameters found will be removed from the array.
    #
    # @param [Hash<Symbol, Parameter>] params A list of available parameters
    # @param [Fixnum] pos The position of the first argument that should be
    #        checked. All arguments ahead of that position will be skipped.
    # @return [Array<Parameter>] Parameters called from the given argument list
    # @see #scoped_args
    def params!(params, pos = 0)
      active_params = []
      to_delete     = []
      each_with_index do |arg, i|
        next if i < pos || arg.nil? || !arg.start_with?('-')

        param = params[(arg.start_with?('--') ? arg[2..-1] : arg[1..1]).to_sym]
        unless param.nil?
          to_delete << i
          scoped_args! param, i + 1 if param.is_a? Option
          active_params << param
        end
      end

      to_delete.reverse.each { |i| delete_at i }

      active_params
    end

    # Gets all arguments passed to a specific scope, i.e. a command or an
    # option.
    #
    # All arguments in the scope will be removed from the array.
    #
    # @param [HasArguments] has_args
    # @param [Fixnum] pos The position of the first argument that should be
    #        checked. All arguments ahead of that position will be skipped.
    def scoped_args!(has_args, pos = 0)
      to_delete = []

      each_with_index do |arg, i|
        next if i < pos
        break if arg.start_with?('-') || !has_args.send(:more_args?)

        to_delete << i
        has_args.send(:<<, arg)
      end

      to_delete.reverse.each { |i| delete_at i }
    end

  end

end
