# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

require 'rubikon/argument_vector'

module Rubikon

  module Application

    # This module contains all DSL-related instance methods of
    # +Application::Base+ and its subclasses. The methods of this module may be
    # used to define and enhance a Rubikon application.
    #
    # @author Sebastian Staudt
    # @see Application::Base
    # @since 0.3.0
    module DSLMethods

      # @return [String] The (first) file where the application has been
      #         defined
      attr_reader :base_file

      # @return [Hash] The active configuration of the application
      attr_reader :config

      # @return [String] The absolute path of the application
      attr_reader :path

      private

      # Checks whether parameter with the given name has been supplied by the
      # user on the command-line.
      #
      # @param [#to_sym] name The name of the parameter to check
      # @see Parameter
      # @since 0.2.0
      #
      # @example
      #  flag :status
      #  command :something do
      #    print_status if active? :status
      #  end
      def active?(name)
        name = name.to_sym
        parameter = @global_parameters[name]
        parameter = @current_command.parameters[name] if parameter.nil?
        return false if parameter.nil?
        parameter.send(:active?)
      end
      alias_method :given?, :active?

      # Call another named command with the given arguments
      #
      # @param [Symbol] command_name The name of the command to call
      # @param [Array<String>] args The arguments to pass to the called command
      # @see ArgumentVector#params!
      # @see Command#run
      def call(command_name, *args)
        args.extend ArgumentVector
        current_command = @current_command
        current_param   = @current_param

        @current_command = @commands[command_name]
        args.params!(@current_command.params).each do |param|
          @current_param = param
          param.send :active!
          @current_param = nil
        end
        @current_command.send :run
        @current_command = current_command
        @current_param   = current_param
      end

      # Define a new application Command or an alias to an existing one
      #
      # @param [String, Hash] name The name of the Command as used in
      #        application parameters. This might also be a Hash where every
      #        key will be an alias to the corresponding value, e.g. <tt>{
      #        :alias => :command }</tt>.
      # @param options (see HasArguments#initialize)
      # @param [Proc] block A block that contains the code that should be
      #        executed when this Command is called, i.e. when the application
      #        is called with the associated parameter
      #
      # @return [Command]
      # @see default
      # @see Command
      # @since 0.2.0
      def command(name, *options, &block)
        command = nil

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
          command = Command.new(self, name, *options, &block)
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
            command.send(:add_param, parameter)
          end
          @parameters.clear
        end

        command
      end

      # Prints a debug message if <tt>$DEBUG</tt> is +true+, e.g. if the user
      # supplied the <tt>--debug</tt> (<tt>-d</tt>) flag.
      #
      # @since 0.2.0
      def debug(message)
        ostream.puts message if $DEBUG
      end

      # Define the default Command of the application, i.e. the Command that is
      # called if no matching Command parameter can be found
      #
      # @param options (see HasArguments#initialize)
      # @param [Proc] block A block that contains the code that should be
      #        executed when this Command is called, i.e. when no command
      #        parameter is given to the application
      #
      # @return [Command] The default Command object
      # @see Command
      # @see command
      # @since 0.2.0
      def default(*options, &block)
        if options.size == 1 && options.first.is_a?(Symbol) && !block_given?
          command :__default => options.first
        else
          command :__default, *options, &block
        end
      end

      # Set the default configuration for this application
      #
      # @param [Hash] config The default configuration to use
      # @see #config
      # @since 0.6.0
      def default_config=(config)
        unless config.is_a? Hash
          raise ArgumentError.new('Configuration has to be a Hash')
        end

        @default_config = config
      end

      # Output a line of text using +IO#puts+ of the error output stream
      #
      # @param [String] text The text to write into the error output stream
      # @since 0.6.0
      def error(text = nil)
        estream.puts text
      end

      # Convenience method for accessing the user-defined error output stream
      #
      # Use this if you want to work directly with the error output stream
      #
      # @return [IO] The error output stream object - usually +$stderr+
      # @since 0.6.0
      #
      # @example
      #  estream.flush
      def estream
        @settings[:estream]
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
      # @since 0.2.0
      #
      # @example
      #  flag :status
      #  flag :st => :status
      #  command :something do
      #    ...
      #  end
      def flag(name, description = nil, &block)
        if name.is_a? Hash
          @parameters << name
        else
          flag = Flag.new(self, name, &block)
          flag.description = description unless description.nil?
          @parameters << flag
        end
      end

      # Create a new flag with the given name to be used globally
      #
      # Global flags are not bound to any command and can therefore be used
      # throughout the application with the same result.
      #
      # @param (see #flag)
      # @see #flag
      # @see Flag
      # @since 0.2.0
      #
      # @example Define a global flag
      #  global_flag :quiet
      # @example Define a global flag with a block to execute
      #  global_flag :quiet do
      #    @quiet = true
      #  end
      # @example Define an alias to a global flag
      #  global_flag :q => :quiet
      def global_flag(name, description = nil, &block)
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
          flag = Flag.new(self, name, &block)
          flag.description = description unless description.nil?
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
      # @since 0.2.0
      #
      # @example Define a global option
      #  global_option :user, 1
      # @example Define a global option with a block to execute
      #  global_option :user, 1 do
      #    @user = args[0]
      #  end
      # @example Define an alias to a global option
      #  global_option :u => :user
      def global_option(name, *options, &block)
        if name.is_a? Hash
          name.each do |alias_name, option_name|
            option = @global_parameters[option_name]
            if option.nil?
              @global_parameters[alias_name] = option_name
            else
              option.aliases << alias_name
              @global_parameters[alias_name] = option
            end
          end
        else
          option = Option.new(self, name, *options, &block)
          @global_parameters.each do |option_alias, option_name|
            if option_name == option.name
              @global_parameters[option_alias] = option
              option.aliases << option_alias
            end
          end
          @global_parameters[option.name] = option
        end
      end

      # Prompts the user for input
      #
      # @param [String, #to_s] prompt A String or other Object responding to
      #        +to_s+ used for displaying a prompt to the user
      # @param [Array<String>] expected A list of strings that are accepted as
      #        valid input. If not empty, input will be checked and the prompt
      #        will be repeated if required.
      # @since 0.2.0
      #
      # @example Display a prompt "Please type something: "
      #  command 'interactive' do
      #    user_provided_value = input 'Please type something'
      #
      #    # Do something with the data
      #    ...
      #  end
      #
      # @example Display a question with validated input
      #  command :question do
      #    good = input 'Do you feel good', 'y', 'n'
      #    ...
      #  end
      def input(prompt = '', *expected)
        prompt << " [#{expected.join '/'}]" unless expected.empty?
        ostream << "#{prompt}: " unless prompt.to_s.empty?
        input = @settings[:istream].gets[0..-2]
        unless expected.empty? || expected.include?(input)
          input = input 'Please provide valid input', *expected
        end
        input
      end

      # Create a new Option with the given name for the next Command
      #
      # @param [Symbol, #to_sym] name The name of the Option (without dashes).
      #        Dashes will be automatically added (+-+ for single-character
      #        options, +--+ for other options). This might also be a Hash
      #        where every key will be an alias to the corresponding value,
      #        e.g. <tt>{ :alias => :option }</tt>.
      # @param options (see HasArguments#initialize)
      # @param [Proc] block An optional code block that should be executed if
      #        this option is used
      # @see Option
      # @since 0.2.0
      #
      # @example
      #   option :message,1
      #   option :m => :message
      #   command :something do
      #     ...
      #   end
      def option(name, *options, &block)
        if name.is_a? Hash
          @parameters << name
        else
          option = Option.new(self, name.to_s, *options, &block)
          @parameters << option
        end
      end

      # Convenience method for accessing the user-defined output stream
      #
      # Use this if you want to work directly with the output stream
      #
      # @return [IO] The output stream object - usually +$stdout+
      # @since 0.2.0
      #
      # @example
      #  ostream.flush
      def ostream
        @settings[:ostream]
      end

      # Defines a block of code used as a hook that should be executed after
      # the command execution has finished
      #
      # @param [Proc] The code block to execute after the command execution has
      #        finished
      # @since 0.4.0
      def post_execute(&block)
        @hooks[:post_execute] = block
      end

      # Defines a block of code used as a hook that should be executed after
      # the application has been initialized
      #
      # @param [Proc] The code block to execute after the application has been
      #        initialized
      # @since 0.4.0
      def post_init(&block)
        @hooks[:post_init] = block
      end

      # Defines a block of code used as a hook that should be executed before
      # the command has been started
      #
      # @param [Proc] The code block to execute before the command has been
      #        started
      # @since 0.4.0
      def pre_execute(&block)
        @hooks[:pre_execute] = block
      end

      # Defines a block of code used as a hook that should be executed before
      # the application has been initialized
      #
      # @param [Proc] The code block to execute before the application has been
      #        initialized
      # @since 0.4.0
      def pre_init(&block)
        @hooks[:pre_init] = block
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
      # @since 0.2.0
      def progress_bar(*options, &block)
        hidden_output do |ostream|
          options = options[0]
          options[:ostream] = ostream

          progress = ProgressBar.new(options)

          block.call(progress)
        end
      end

      # Output text using +IO#<<+ of the output stream
      #
      # @param [String] text The text to write into the output stream
      # @since 0.2.0
      def put(text)
        ostream << text
        ostream.flush
      end

      # Output a character using +IO#putc+ of the output stream
      #
      # @param [String, Numeric] char The character to write into the output
      #        stream
      # @since 0.2.0
      def putc(char)
        ostream.putc char
      end

      # Output a line of text using +IO#puts+ of the output stream
      #
      # @param [String] text The text to write into the output stream
      # @since 0.2.0
      def puts(text = nil)
        ostream.puts text
      end

      # Sets an application setting
      #
      # @param [Symbol, #to_sym] setting The name of the setting to change
      # @param [Object] value The value the setting should be changed to
      # @since 0.2.0
      #
      # Available settings
      # +autorun+::      If +true+, let the application run as soon as its
      #                  class is defined. This is generally useful for simple
      #                  "code and run" applications.
      # +colors+::       If +true+, enables colored output using ColoredIO
      # +config_file+::  The name of the config file to search
      # +config_paths+:: The paths to search for config files
      # +estream+::      Defines an error output stream to use
      # +help_banner+::  Defines a banner for the help message
      # +istream+::      Defines an input stream to use
      # +name+::         Defines the name of the application
      # +ostream+::      Defines an output stream to use
      # +raise_errors+:: If +true+, raise errors, otherwise fail gracefully
      #
      # @example
      #  set :name, 'My App'
      #  set :autorun, false
      def set(setting, value)
        setting = setting.to_sym
        if setting == :estream
          self.estream = value
        elsif setting == :ostream
          self.ostream = value
        else
          @settings[setting.to_sym] = value
        end
      end

      # Saves the current configuration into a configuration file
      #
      # The file name and format are specified in the application settings.
      #
      # @param [:global, :local, :user, String] Either one of the default
      #        scopes or a specific path. The scopes map to a special path. On
      #        UNIX systems this is +/etc+ for global configurations, the
      #        user's home directory (+~+) for user configurations and the
      #        current working directory (+.+) for local configurations.
      # @see #default_config=
      # @since 0.6.0
      def save_config(scope = :user)
        case scope
          when :global
            if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/
              path = ENV['ALLUSERSPROFILE']
            else
              path = '/etc'
            end
          when :local
            path = File.expand_path '.'
          when :user
            path = File.expand_path '~'
          else
            path = scope
        end

        @config_factory.save_config @config,
          File.join(path, @settings[:config_file])
      end

      # Displays a throbber while the given block is executed
      #
      # @param [Proc] block The block to execute while the throbber is
      #        displayed
      # @see Throbber
      # @since 0.2.0
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

    end

  end

end
