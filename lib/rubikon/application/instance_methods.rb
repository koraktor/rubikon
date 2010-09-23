# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rubikon/command'
require 'rubikon/exceptions'
require 'rubikon/flag'
require 'rubikon/option'
require 'rubikon/progress_bar'
require 'rubikon/throbber'

module Rubikon

  module Application

    # This module contains all instance methods of +Application::Base+ and its
    # subclasses.
    #
    # @author Sebastian Staudt
    # @see Application::Base
    # @since 0.2.0
    module InstanceMethods

      # @return [String] The absolute path of the application
      attr_reader :path

      # Initialize with default settings
      #
      # If you really need to override this in your application class, be sure
      # to call +super+
      #
      # @see #set
      def initialize
        @commands              = {}
        @current_command       = nil
        @current_global_option = nil
        @global_parameters     = {}
        @initialized           = false
        @parameters            = []
        @path                  = File.dirname($0)
        @settings              = {
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
          init unless @initialized

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
          result = command.run(*args)
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

      # Returns the arguments for the currently executed Command
      #
      # @return [Array]
      #
      # @example
      #  command :something do
      #    puts arguments[0]
      #  end
      def arguments
        unless @current_command.nil?
          @current_command.arguments
        else
          @current_global_option.arguments
        end
      end
      alias_method :args, :arguments

      # Define a new application Command or an alias to an existing one
      #
      # @param [String, Hash] name The name of the Command as used in
      #        application parameters. This might also be a Hash where every
      #        key will be an alias to the corresponding value, e.g. <tt>{
      #        :alias => :command }</tt>.
      # @param [String] description A description for this Command for use in
      #        the application's help screen
      # @param [Proc] block A block that contains the code that should be
      #        executed when this Command is called, i.e. when the application
      #        is called with the associated parameter
      #
      # @return [Command]
      def command(name, description = nil, &block)
        if name.is_a? Hash
          name.each do |alias_name, command_name|
            command = @commands[command_name]
            if command.nil?
              @commands[alias_name] = command_name
            else
              command.aliases << alias_name
              @commands[alias_name] = command
            end
          end
        else
          command = Command.new(self, name, &block)
          command.description = description unless description.nil?
          @commands.each do |command_alias, command_name|
            if command_name == command.name
              @commands[command_alias] = command
              command.aliases << command_alias
            end
          end
          @commands[command.name] = command
        end

        unless command.nil? || @parameters.empty?
          @parameters.each do |parameter|
            command << parameter
          end
          @parameters.clear
        end

        command
      end

      # Prints a debug message if <tt>$DEBUG</tt> is +true+, e.g. if the user
      # supplied the <tt>--debug</tt> (<tt>-d</tt>) flag.
      def debug(message)
        ostream.puts message if $DEBUG
      end

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

      # Define the default Command of the application, i.e. the Command that is
      # called if no matching Command parameter can be found
      #
      # @param [String] description A description for this Command for use in
      #        the application's help screen
      # @param [Proc] block A block that contains the code that should be
      #        executed when this Command is called, i.e. when no command
      #        parameter is given to the application
      #
      # @return [Command] The default Command object
      def default(description = nil, &block)
        if description.is_a? Symbol
          command({ :__default => description })
        else
          command(:__default, description, &block)
        end
      end

      # Create a new Flag with the given name for the next Command
      #
      # @param [Symbol, #to_sym] name The name of the flag (without dashes).
      #        Dashes will be automatically added (<tt>-</tt> for
      #        single-character flags, <tt>--</tt> for other flags). This might
      #        also be a Hash where every key will be an alias to the
      #        corresponding value, e.g. <tt>{ :alias => :flag }</tt>.
      # @param [Proc] block An optional code block that should be executed if
      #        this flag is used
      #
      # @example
      #  flag :status
      #  flag :st => :status
      #  command :something do
      #    ...
      #  end
      def flag(name, &block)
        if name.is_a? Hash
          @parameters << name
        else
          @parameters << Flag.new(name, &block)
        end
      end

      # Checks whether parameter with the given name has been supplied by the
      # user on the command-line.
      #
      # @param [#to_sym] name The name of the parameter to check
      #
      # @example
      #  flag :status
      #  command :something do
      #    print_status if given? :status
      #  end
      def given?(name)
        name = name.to_sym
        parameter = @global_parameters[name]
        parameter = @current_command.parameters[name] if parameter.nil?
        return false if parameter.nil?
        parameter.active?
      end

      # Create a new flag with the given name to be used globally
      #
      # Global flags are not bound to any command and can therefore be used
      # throughout the application with the same result.
      #
      # @param (see #flag)
      # @see #flag
      # @see Flag
      #
      # @example Define a global flag
      #  global_flag :quiet
      # @example Define a global flag with a block to execute
      #  global_flag :quiet do
      #    @quiet = true
      #  end
      # @example Define an alias to a global flag
      #  global_flag :q => :quiet
      def global_flag(name, &block)
        if name.is_a? Hash
          name.each do |alias_name, flag_name|
            flag = @global_parameters[flag_name]
            if flag.nil?
              @global_parameters[alias_name] = flag_name
            else
              flag.aliases << alias_name
              @global_parameters[alias_name] = flag
            end
          end
        else
          flag = Flag.new(name, &block)
          @global_parameters.each do |flag_alias, flag_name|
            if flag_name == flag.name
              @global_parameters[flag_alias] = flag
              flag.aliases << flag_alias
            end
          end
          @global_parameters[flag.name] = flag
        end
      end

      # Create a new option with the given name to be used globally
      #
      # Global options are not bound to any command and can therefore be used
      # throughout the application with the same result.
      #
      # @param (see #option)
      # @see #option
      # @see Option
      #
      # @example Define a global option
      #  global_option :user, 1
      # @example Define a global option with a block to execute
      #  global_option :user, 1 do
      #    @user = args[0]
      #  end
      # @example Define an alias to a global option
      #  global_option :u => :user
      def global_option(name, arg_count = 0, &block)
        if name.is_a? Hash
          name.each do |alias_name, option_name|
            option = @global_parameters[option_name]
            if option.nil?
              @global_parameters[option_name] = option_name
            else
              option.aliases << alias_name
              @global_parameters[alias_name] = option
            end
          end
        else
          option = Option.new(name, arg_count, &block)
          @global_parameters.each do |option_alias, option_name|
            if option_name == option.name
              @global_parameters[option_alias] = option
              option.aliases << option_alias
            end
          end
          @global_parameters[option.name] = option
        end
      end

      # Defines a command for displaying a help screen
      #
      # This takes any defined commands and it's corresponding options and
      # descriptions and displays them in a user-friendly manner.
      def help_command
        command :help, 'Display this help screen' do
          put @settings[:help_banner]

          help = {}
          @commands.each_value do |command|
            help[command.name.to_s] = command.description
          end

          default_description = help.delete('__default')
          if default_description.nil?
            puts " command [args]\n\n"
          else
            puts " [command] [args]\n\n"
            puts "Without command: #{default_description}\n\n"
          end

          puts "Commands:"
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

      # Prompts the user for input
      #
      # @param [String, #to_s] prompt A String or other Object responding to
      #        +to_s+ used for displaying a prompt to the user
      #
      # @example Display a prompt "Please type something: "
      #  action 'interactive' do
      #    user_provided_value = input 'Please type something'
      #
      #    # Do something with the data
      #    ...
      #  end
      def input(prompt = '')
        unless prompt.to_s.empty?
          ostream << "#{prompt}: "
        end
        @settings[:istream].gets[0..-2]
      end

      # Output text using +IO#<<+ of the output stream
      #
      # @param [String] text The text to write into the output stream
      def put(text)
        @settings[:ostream] << text
        @settings[:ostream].flush
      end

      # Output a character using +IO#putc+ of the output stream
      #
      # @param [String, Numeric] char The character to write into the output
      #        stream
      def putc(char)
        @settings[:ostream].putc char
      end

      # Output a line of text using +IO#puts+ of the output stream
      #
      # @param [String] text The text to write into the output stream
      def puts(text)
        @settings[:ostream].puts text
      end

      # Create a new Option with the given name for the next Command
      #
      # @param [Symbol, #to_sym] name The name of the Option (without dashes).
      #        Dashes will be automatically added (+-+ for single-character
      #        options, +--+ for other options). This might also be a Hash
      #        where every key will be an alias to the corresponding value,
      #        e.g. <tt>{ :alias => :option }</tt>.
      # @param [Numeric] arg_count The number of arguments this option takes.
      #        Use +0+ for no required arguments or a negative value for an
      #        arbitrary number of arguments
      # @param [Proc] block An optional code block that should be executed if
      #        this option is used
      #
      # @example
      #   option :message,1
      #   option :m => :message
      #   command :something do
      #     ...
      #   end
      def option(name, arg_count = 0, &block)
        if name.is_a? Hash
          @parameters << name
        else
          @parameters << Option.new(name.to_s, arg_count, &block)
        end
      end

      # Convenience method for accessing the user-defined output stream
      #
      # Use this if you want to work directly with the output stream
      #
      # @return [IO] The output stream object - usually +$stdout+
      #
      # @example
      #  ostream.flush
      def ostream
        @settings[:ostream]
      end

      # Returns the parameters for the currently executed command
      #
      # @return [Array] The parameters of the currently executed command
      # @see Command
      #
      # @example
      #  option :message, 1
      #  command :something do
      #    puts parameters[:message].args[0] if given? :message
      #  end
      def parameters
        @current_command.parameters
      end
      alias_method :params, :parameters

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

      # Displays a progress bar while the given block is executed
      #
      # Inside the block you have access to a instance of ProgressBar. So you
      # can update the progress using <tt>ProgressBar#+</tt>.
      #
      # @param [Hash] options A Hash of options that should be passed to the
      #        ProgressBar object.
      # @param [Proc] block The block to execute
      # @yield [ProgressBar] The given block may be used to change the values
      #        of the progress bar
      # @yieldparam [ProgressBar] progress The progress bar indicating the
      #             progress of the block
      #
      # @example
      #  progress_bar(:maximum => 5) do |progress|
      #    5.times do |file|
      #      File.read("any#{file}.txt")
      #      progress.+
      #    end
      #  end
      #
      # @see ProgressBar
      def progress_bar(*options, &block)
        hidden_output do |ostream|
          options = options[0]
          options[:ostream] = ostream

          progress = ProgressBar.new(options)

          block.call(progress)
        end
      end

      # Sets an application setting
      #
      # @param [Symbol, #to_sym] setting The name of the setting to change
      # @param [Object] value The value the setting should be changed to
      #
      # Available settings
      # +autorun+::        If true, let the application run as soon as its
      #                    class is defined
      # +help_banner+::    Defines a banner for the help message
      #                    (<em>unused</em>)
      # +istream+::        Defines an input stream to use
      # +name+::           Defines the name of the application
      # +ostream+::        Defines an output stream to use
      # +raise_errors+::   If true, raise errors, otherwise fail gracefully
      #
      # @example
      #  set :name, 'My App'
      #  set :autorun, false
      def set(setting, value)
        @settings[setting.to_sym] = value
      end

      # Displays a throbber while the given block is executed
      #
      # @param [Proc] block The block to execute while the throbber is
      #        displayed
      # @yield While the block is executed a throbber is displayed
      #
      # @example Using the throbber helper
      #  command :slow do
      #    throbber do
      #      # Add some long running code here
      #      ...
      #    end
      #  end
      def throbber(&block)
        hidden_output do |ostream|
          code_thread = Thread.new { block.call }
          throbber_thread = Throbber.new(ostream, code_thread)

          code_thread.join
          throbber_thread.join
        end
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
