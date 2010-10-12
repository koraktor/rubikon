# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rubikon/application/sandbox'
require 'rubikon/command'
require 'rubikon/exceptions'
require 'rubikon/flag'
require 'rubikon/option'
require 'rubikon/progress_bar'
require 'rubikon/throbber'

module Rubikon

  module Application

    # This module contains internal instance methods of +Application::Base+ and
    # its subclasses.
    #
    # @author Sebastian Staudt
    # @see Application::Base
    # @since 0.2.0
    module InstanceMethods

      # @param [Parameter] Sets the parameter that's currently executed
      attr_writer :current_param

      # @return [Application::Sandbox] The sandbox this application runs in
      attr_reader :sandbox

      # Initialize with default settings
      #
      # If you really need to override this in your application class, be sure
      # to call +super+
      #
      # @see #set
      def initialize
        @commands             = {}
        @current_command      = nil
        @current_global_param = nil
        @current_param        = nil
        @global_parameters    = {}
        @hooks                = {}
        @initialized          = false
        @parameters           = []
        @path                 = File.dirname($0)
        @sandbox              = Sandbox.new(self)
        @settings             = {
          :autorun         => true,
          :help_as_default => true,
          :help_banner     => "Usage: #{$0}",
          :istream         => $stdin,
          :name            => self.class.to_s,
          :ostream         => $stdout,
          :raise_errors    => false
        }
      end

      # Run this application
      #
      # Calling this method explicitly is not required when you want to create
      # a simple application (having one main class inheriting from
      # Rubikon::Application). But it's useful for testing or if you want to
      # have some sort of sub-applications.
      #
      # @param [Array<String>] args The command line arguments that should be
      #        given to the application as options
      def run(args = ARGV)
        begin
          unless @initialized
            hook :pre_init
            init
            hook :post_init
          end

          command, parameters, args = parse_arguments(args)

          parameters.each do |parameter|
            if parameter.is_a? Option
              parameter.check_args
              @current_global_option = parameter
            end
            parameter.active!
            @current_global_option = nil
          end

          @current_command = command
          hook :post_execute
          result = command.run(*args)
          hook :post_execute
          @current_command = nil
          result
        rescue
          raise $! if @settings[:raise_errors]

          puts "Error:\n    #{$!.message}"
          puts "    #{$!.backtrace.join("\n    ")}" if $DEBUG
          exit 1
        end
      end

      private

      # Defines a global Flag for enabling debug output
      #
      # This will define a Flag <tt>--debug</tt> (with alias <tt>-d</tt>) to
      # enable debug output.
      # Using it sets Ruby's global variable <tt>$DEBUG</tt> to +true+.
      #
      # @return [Flag]
      def debug_flag
        global_flag :debug do
          $DEBUG = true
        end
        global_flag :d => :debug
      end

      # Defines a command for displaying a help screen
      #
      # This takes any defined commands and it's corresponding options and
      # descriptions and displays them in a user-friendly manner.
      def help_command
        commands = @commands
        global_parameters = @global_parameters
        settings = @settings

        command :help, nil, 'Display this help screen' do
          put settings[:help_banner]

          help = {}
          commands.each_value do |command|
            help[command.name.to_s] = command.description
          end

          global_params = ''
          global_parameters.values.uniq.sort {|a,b| a.name.to_s <=> b.name.to_s }.each do |param|
            global_params << ' ['
            ([param.name] + param.aliases).each_with_index do |name, index|
              name = name.to_s
              global_params << '|' if index > 0
              global_params << '-' if name.size > 1
              global_params << "-#{name}"
            end
            global_params << ' ...' if param.is_a?(Option)
            global_params << ']'
          end

          default_description = help.delete('__default')
          if default_description.nil?
            puts "#{global_params} command [args]\n\n"
          else
            puts "#{global_params} [command] [args]\n\n"
            puts "Without command: #{default_description}\n\n"
          end

          puts 'Commands:'
          max_command_length = help.keys.max { |a, b| a.size <=> b.size }.size
          help.sort_by { |name, description| name }.each do |name, description|
            puts "  #{name.ljust(max_command_length)}    #{description}"
          end
        end
      end

      # Hide output inside the given block and print it after the block has
      # finished
      #
      # @param [Proc] block The block that should not print output while it's
      #        running
      #
      # If the block needs to print to the real IO stream, it can access it
      # using its first parameter.
      def hidden_output(&block)
        current_ostream = @settings[:ostream]
        @settings[:ostream] = StringIO.new

        block.call(current_ostream)

        current_ostream << @settings[:ostream].string
        @settings[:ostream] = current_ostream
      end

      # Executes the hook with the secified name
      #
      # @param [Symbol] name The name of the hook to execute
      def hook(name)
        @hooks[name].call unless @hooks[name].nil?
      end

      # This method is called once for each application and is used to
      # initialize anything that needs to be ready before the application is
      # run, but <em>after</em> the application is setup, i.e. after the user
      # has defined the application class.
      def init
        debug_flag
        help_command
        verbose_flag

        if @settings[:help_as_default] && !@commands.keys.include?(:__default)
          default :help
        end

        @initialized = true
      end

      # Parses the command-line arguments given to the application by the
      # user. This distinguishes between commands, global flags and command
      # flags
      #
      # @param [Array] args The command-line arguments
      # @return [Command, Array<Symbol>, Array] The command to execute, the
      #         parameters of this command that have been supplied and any
      #         additional command-line arguments supplied
      def parse_arguments(args)
        command_arg = args.shift
        if command_arg.nil? || command_arg.start_with?('-')
          command = @commands[:__default]
          args.unshift(command_arg) unless command_arg.nil?
          raise NoDefaultCommandError if command.nil?
        else
          command = @commands[command_arg.to_sym]
          raise UnknownCommandError.new(command_arg) if command.nil?
        end

        parameter  = nil
        parameters = []
        args.dup.each do |arg|
          if arg.start_with?('--')
            parameter = @global_parameters[arg[2..-1].to_sym]
          elsif arg.start_with?('-')
            parameter = @global_parameters[arg[1..-1].to_sym]
          else
            if !parameter.nil? && parameter.more_args?
              parameter.args << args.delete(arg)
            else
              parameter = nil
            end
            next
          end

          unless parameter.nil?
            parameters << parameter
            args.delete(arg)
          end
        end

        return command, parameters, args
      end

      # Defines a global Flag for enabling verbose output
      #
      # This will define a Flag <tt>--verbose</tt> and <tt>-v</tt> to enable
      # verbose output.
      # Using it sets Ruby's global variable <tt>$VERBOSE</tt> to +true+.
      #
      # @return [Flag] The debug Flag object
      def verbose_flag
        global_flag :verbose do
          $VERBOSE = true
        end
        global_flag :v => :verbose
      end

    end

  end

end
