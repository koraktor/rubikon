# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'pathname'
require 'stringio'

require 'rubikon/application/sandbox'
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
        @commands             = {}
        @current_command      = nil
        @current_global_param = nil
        @current_param        = nil
        @global_parameters    = {}
        @hooks                = {}
        @initialized          = false
        @parameters           = []
        @sandbox              = Sandbox.new(self)
        @settings             = {
          :autorun         => true,
          :colors          => true,
          :config_file     => "#{self.class.to_s.downcase}.yml",
          :help_as_default => true,
          :istream         => $stdin,
          :name            => self.class.to_s,
          :raise_errors    => false
        }

        @settings[:config_paths] = []
        if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/
          @settings[:config_paths] << ENV['ALLUSERSPROFILE']
        else
          @settings[:config_paths] << '/etc'
        end
        @settings[:config_paths] << File.expand_path('~')
        @settings[:config_paths] << File.expand_path('.')

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
          command, parameters, args = InstanceMethods.
            instance_method(:parse_arguments).bind(self).call(args)

          parameters.each do |parameter|
            @current_global_param = parameter
            parameter.send :check_args if parameter.is_a? Option
            parameter.send :active!
            @current_global_param = nil
          end

          @config = Config::Factory.new(@settings[:config_file],
            @settings[:config_paths], @settings[:config_format]).config

          @current_command = command
          hook.call(:pre_execute)
          result = command.send(:run, *args)
          hook.call(:post_execute)
          @current_command = nil

          result
        rescue
          raise $! if @settings[:raise_errors]

          puts "r{Error:}\n    #{$!.message}"
          puts "     at #{$!.backtrace.join("\n     at ")}" if $DEBUG
          exit 1
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

        if @settings[:help_as_default] && !@commands.keys.include?(:__default)
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
        receiver = @current_param || @current_global_param || @current_command
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

        args = args.map do |arg|
          if !arg.start_with?('--') && arg.start_with?('-') && arg.size > 2
            arg[1..-1].split('').map { |a| "-#{a}"}
          else
            arg
          end
        end.flatten

        parameter  = nil
        parameters = []
        args.dup.each do |arg|
          if arg.start_with?('--')
            parameter = @global_parameters[arg[2..-1].to_sym]
          elsif arg.start_with?('-')
            parameter = @global_parameters[arg[1..-1].to_sym]
          else
            if !parameter.nil? && parameter.send(:more_args?)
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
        ostream.rewind if ostream.is_a? StringIO || !ostream.stat.chardev?
        ColoredIO.remove_color_filter(ostream)
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
