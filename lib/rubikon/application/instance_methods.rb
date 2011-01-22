# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2011, Sebastian Staudt

require 'pathname'
require 'stringio'

require 'rubikon/application/sandbox'
require 'rubikon/argument_vector'
require 'rubikon/colored_io'
require 'rubikon/command'
require 'rubikon/config/factory'
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

      # @return [Parameter] The parameter that's currently executed
      attr_accessor :current_param

      # @return [Application::Sandbox] The sandbox this application runs in
      attr_reader :sandbox

      # Initialize with default settings
      #
      # If you really need to override this in your application class, be sure
      # to call +super+
      #
      # @see #set
      def initialize
        @commands          = {}
        @current_command   = nil
        @current_param     = nil
        @default_config    = {}
        @global_parameters = {}
        @hooks             = {}
        @initialized       = false
        @parameters        = []
        @sandbox           = Sandbox.new(self)
        @settings          = {
          :autohelp        => true,
          :autorun         => true,
          :colors          => true,
          :config_file     => "#{self.class.to_s.downcase}.yml",
          :help_as_default => true,
          :istream         => $stdin,
          :name            => self.class.to_s,
          :raise_errors    => false
        }

        if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/
          global_config_path = ENV['ALLUSERSPROFILE']
        else
          global_config_path = '/etc'
        end

        @settings[:config_paths] = [
          global_config_path, File.expand_path('~'), File.expand_path('.')
        ]

        self.estream = $stderr
        self.ostream = $stdout
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
        hook = InstanceMethods.instance_method(:hook).bind(self)

        begin
          InstanceMethods.instance_method(:init).bind(self).call
          global_params, command, command_params = InstanceMethods.
            instance_method(:parse_arguments).bind(self).call(args)

          @config_factory = Config::Factory.new(@settings[:config_file],
            @settings[:config_paths], @settings[:config_format])
          @config = @default_config.merge @config_factory.config

          global_params.each do |param|
            @current_param = param
            param.send :active!
            @current_param = nil
          end

          @current_command = command
          hook.call(:pre_execute)

          command_params.each do |param|
            @current_param = param
            param.send :active!
            @current_param = nil
          end

          result = command.send(:run)
          hook.call(:post_execute)
          @current_command = nil

          result
        rescue Interrupt
          error "\nInterrupted... exiting."
        rescue
          raise $! if @settings[:raise_errors]

          if @settings[:autohelp] && @commands.key?(:help) &&
             $!.is_a?(UnknownCommandError)
            call :help, $!.command
          else
            error "r{Error:}\n    #{$!.message}"
            error "     at #{$!.backtrace.join("\n     at ")}" if $DEBUG
            exit 1
          end
        ensure
          InstanceMethods.instance_method(:reset).bind(self).call
        end
      end

      private

      # Sets the (first) file this application has been defined in.
      #
      # This also sets the path of the application used to load external
      # command code and the default banner for the help screen.
      #
      # @param [String] file The (first) file of the class definition
      # @see DSLMethods#base_file
      # @see DSLMethods#path
      # @since 0.4.0
      def base_file=(file)
        @base_file = file
        @path      = File.dirname(file)

        @settings[:help_banner] ||= "Usage: #{Pathname.new(file).relative_path_from(Pathname.new(Dir.getwd))}"
      end

      # Defines a global Flag for enabling debug output
      #
      # This will define a Flag <tt>--debug</tt> (with alias <tt>-d</tt>) to
      # enable debug output.
      # Using it sets Ruby's global variable <tt>$DEBUG</tt> to +true+.
      #
      # @return [Flag] The debug flag
      def debug_flag
        global_flag :debug do
          $DEBUG = true
        end
        global_flag :d => :debug
      end

      # Sets the error output stream of the application
      #
      # If colors are enabled, this checks if the stream supports the
      # +color_filter+ method and enables the +ColoredIO+ if not.
      #
      # @param [IO] estream The output stream to use
      # @see ColoredIO.add_color_filter
      # @since 0.6.0
      def estream=(estream)
        if !estream.respond_to?(:color_filter)
          ColoredIO.add_color_filter(estream, @settings[:colors])
        end
        @settings[:estream] = estream
      end

      # Prints a help screen for this application
      #
      # @param [String] info A additional information string to be displayed
      #        right after usage information
      # @since 0.6.0
      def help(info = nil)
        help = {}
        @commands.each_value do |command|
          help[command.name.to_s] = command.description
        end
        help.delete('__default')

        if @commands.key? :__default
          puts " [command] [args]\n\n"
        else
          puts " command [args]\n\n"
        end

        puts "#{info}\n\n" unless info.nil?

        puts 'Commands:'
        max_command_length = help.keys.max_by { |a| a.size }.size
        help.sort_by { |name, description| name }.each do |name, description|
          puts "  #{name.ljust(max_command_length)}    #{description}"
        end

        if @commands.key?(:__default) &&
           @commands[:__default].description != '<hidden>'
          put "\nYou can also call this application without a command:"
          puts @commands[:__default].help(false) + "\n"
        end
      end

      # Defines a command for displaying a help screen
      #
      # This takes any defined commands and it's corresponding options and
      # descriptions and displays them in a user-friendly manner.
      def help_command
        commands = @commands
        global_parameters = @global_parameters
        settings = @settings

        command :help, 'Show help for the application or a single command',
                :cmd => :optional do
          put settings[:help_banner]

          global_params = ''
          global_parameters.values.uniq.sort_by { |a| a.name.to_s }.each do |param|
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
          put global_params

          app_help = lambda { |info| @__app__.instance_eval { help(info) } }

          unless cmd.nil?
            cmd = cmd.to_sym
            if commands.key? cmd
              puts commands[cmd].help
            else
              app_help.call("The command \"#{cmd}\" is undefined. The following commands are available:")
            end
          else
            app_help.call(nil)
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
        current_ostream = ostream
        self.ostream = StringIO.new

        block.call(current_ostream)

        current_ostream << ostream.string
        self.ostream = current_ostream
      end

      # Executes the hook with the secified name
      #
      # @param [Symbol] name The name of the hook to execute
      # @since 0.4.0
      def hook(name)
        @sandbox.instance_eval(&@hooks[name]) unless @hooks[name].nil?
      end

      # This method is called once for each application and is used to
      # initialize anything that needs to be ready before the application is
      # run, but <em>after</em> the application is setup, i.e. after the user
      # has defined the application class.
      def init
        return if @initialized

        hook = InstanceMethods.instance_method(:hook).bind(self)

        @current_command      = nil
        @current_param        = nil
        @current_global_param = nil

        hook.call(:pre_init)

        InstanceMethods.instance_method(:debug_flag).bind(self).call
        InstanceMethods.instance_method(:help_command).bind(self).call
        InstanceMethods.instance_method(:verbose_flag).bind(self).call

        if @settings[:help_as_default] && @commands.key?(:help) &&
           !@commands.key?(:__default)
          default :help
        end

        @initialized = true

        hook.call(:post_init)
      end

      # This is used to determine the receiver of a method call inside the
      # application code.
      #
      # This is used to have a convenient way to access e.g. paramter
      # arguments.
      #
      # This will delegate a method call to the currently executed parameter
      # if the receiving object exists and responds to the desired method.
      # Currently executed means the application's execution is inside a
      # parameter's code block at the moment, i.e. a call to a missing method
      # inside a parameter's code block will trigger this behavior.
      #
      # @example Access a command's arguments
      #   command :args, [:one, :two] do
      #     puts "One: #{one}, Two: #{two}"
      #   end
      # @since 0.4.0
      def method_missing(name, *args, &block)
        receiver = @current_param || @current_command
        if receiver.nil? || (!receiver.respond_to?(name) &&
           !receiver.public_methods(false).include?(name))
          super
        else
          receiver.send(name, *args, &block)
        end
      end

      # Sets the output stream of the application
      #
      # If colors are enabled, this checks if the stream supports the
      # +color_filter+ method and enables the +ColoredIO+ if not.
      #
      # @param [IO] ostream The output stream to use
      # @see ColoredIO.add_color_filter
      def ostream=(ostream)
        if !ostream.respond_to?(:color_filter)
          ColoredIO.add_color_filter(ostream, @settings[:colors])
        end
        @settings[:ostream] = ostream
      end

      # Parses the command-line arguments given to the application by the
      # user. This distinguishes between commands, global flags and command
      # flags
      #
      # @param [String] argv The command-line arguments
      # @raise [NoDefaultCommandError] if no command can be found and no
      #        default command exists
      # @raise [UnknownParameterError] if an unknown parameter is found
      # @raise [UnknownParameterError] if an unknown command is found
      # @return [Array<Parameter>] one All global parameters that have been
      #         supplied
      # @return [Command] two The command to execute, the parameters of this
      #         command that have been supplied
      # @return [Array<Parameter>] three All parameters of that command that have
      #         been supplied
      def parse_arguments(argv)
        argv.extend ArgumentVector

        argv.expand!

        command, command_index = argv.command! @commands
        raise NoDefaultCommandError if command.nil?

        command_params = argv.params! command.params, command_index
        global_params  = argv.params! @global_parameters

        argv.scoped_args! command

        unless argv.empty?
          first = argv.first
          if first.start_with? '-'
            raise UnknownParameterError.new(first)
          else
            raise UnknownCommandError.new(first)
          end
        end

        return global_params, command, command_params
      end

      # Resets this application to its initial state
      #
      # This rewinds the output stream, removes the color features from the and
      # resets all commands and global parameters.
      #
      # @see ColoredIO.remove_color_filter
      # @see Command#reset
      # @see HasArguments#reset
      # @see IO#rewind
      # @see Parameter#reset
      # @since 0.4.0
      def reset
        [estream, ostream].each do |stream|
          stream.rewind if stream.is_a? StringIO || !stream.stat.chardev?
          ColoredIO.remove_color_filter(estream)
        end
        (@commands.values + @global_parameters.values).uniq.each do |param|
          param.send :reset
        end
      end

      # Defines a global Flag for enabling verbose output
      #
      # This will define a Flag <tt>--verbose</tt> and <tt>-v</tt> to enable
      # verbose output.
      # Using it sets Ruby's global variable <tt>$VERBOSE</tt> to +true+.
      #
      # @return [Flag] The verbose Flag object
      def verbose_flag
        global_flag :verbose do
          $VERBOSE = true
        end
        global_flag :v => :verbose
      end

    end

  end

end
