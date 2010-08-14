# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rubikon/progress_bar'
require 'rubikon/throbber'

module Rubikon

  module Application

    module InstanceMethods

      #def self.included(mod)
      #  mod.class_variable_set(:@@current, {})
      #end

      # Initialize with default settings (see set for more detail)
      #
      # If you really need to override this in your application class, be sure to
      # call +super+
      def initialize
        @actions            = {}
        @aliases            = {}
        @current_definition = {}
        @default            = nil
        @initialized        = false
        @settings           = {
          :autorun        => true,
          :auto_shortopts => true,
          :dashed_options => true,
          :help_banner    => "Usage: #{$0}",
          :istream        => $stdin,
          :name           => self.class.to_s,
          :ostream        => $stdout,
          :raise_errors   => false
        }
      end

      # Define an Application Action
      #
      # +name+::    The name of the action. Used as an option parameter.
      # +options+:: A Hash of options to be used on the created Action
      #             (default: <tt>{}</tt>)
      # +block+::   A block containing the code that should be executed when this
      #             Action is called, i.e. when the Application is called with
      #             the associated option parameter
      def action(name, options = {}, &block)
        raise 'No block given' unless block_given?

        action = Action.new(options, &block)

        key = name.to_s
        if @settings[:dashed_options]
          if @settings[:auto_shortopts]
            short_key = "-#{key[0..0]}"
            @actions[short_key.to_sym] = action unless @actions.key? short_key
          end
          key = "--#{key}"
        end

        @actions[key.to_sym] = action
      end

      # Define an alias to an Action
      #
      # +name+::   The name of the alias
      # +action+:: The name of the Action that should be aliased
      #
      # Example:
      #
      #  action_alias :doit, :dosomething
      def action_alias(name, action)
        @aliases[name.to_sym] = action.to_sym
      end

      # Define the default Action of the Application
      #
      # +options+:: A Hash of options to be used on the created Action
      #             (default: <tt>{}</tt>)
      # +block+::   A block containing the code that should be executed when this
      #             Action is called, i.e. when no option is given to the
      #             Application
      def default(options = {}, &block)
        @default = Action.new(options, &block)
      end

      # Prompts the user for input
      #
      # If +prompt+ is not empty this will display a prompt using
      # <tt>prompt.to_s</tt>.
      #
      # +prompt+:: A String or other Object responding to +to_s+ used for
      #            displaying a prompt to the user (default: <tt>''</tt>)
      #
      # Example:
      #
      #  action 'interactive' do
      #    # Display a prompt "Please type something: "
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

      # Convenience method for accessing the user-defined output stream
      #
      # Use this if you want to work directly with the output stream
      #
      # Example:
      #
      #  ostream.flush
      def ostream
        @settings[:ostream]
      end

      # Displays a progress bar while the given block is executed
      #
      # Inside the block you have access to a instance of ProgressBar. So you
      # can update the progress using <tt>ProgressBar#+</tt>.
      #
      # +options+:: A Hash of options that should be passed to the ProgressBar
      #             object. For available options see ProgressBar
      # +block+::   The block to execute
      #
      # Example:
      #
      #  progress_bar(:maximum => 5) do |progress|
      #    5.times do |file|
      #      File.read("any#{file}.txt")
      #      progress.+
      #    end
      #  end
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
      # +text+:: The text to write into the output stream
      def put(text)
        @settings[:ostream] << text
        @settings[:ostream].flush
      end

      # Output a character using +IO#putc+ of the output stream
      #
      # +char+:: The character to write into the output stream
      def putc(char)
        @settings[:ostream].putc char
      end

      # Output a line of text using +IO#puts+ of the output stream
      #
      # +text+:: The text to write into the output stream
      def puts(text)
        @settings[:ostream].puts text
      end

      # Run this application
      #
      # +args+:: The command line arguments that should be given to the
      #          application as options
      #
      # Calling this method explicitly is not required when you want to create a
      # simple application (having one main class inheriting from
      # Rubikon::Application). But it's useful for testing or if you want to have
      # some sort of sub-applications.
      def run(args = ARGV)
        init unless @initialized
        action_results = []

        begin
          if !@default.nil? and args.empty?
            action_results << @default.run
          else
            parse_options(args).each do |action, args|
              action_results << @actions[action].run(*args)
            end
          end
        rescue
          raise $! if @settings[:raise_errors]

          puts "Error:\n    #{$!.message}"
          puts "    #{$!.backtrace.join("\n    ")}" if $DEBUG
          exit 1
        end

        action_results
      end

      # Sets an application setting
      #
      # +setting+:: The name of the setting to change, will be symbolized first.
      # +value+::   The value the setting should be changed to
      #
      # Available settings
      # +autorun+::        If true, let the application run as soon as its class
      #                    is defined
      # +dashed_options+:: If true, each option is prepended with a double-dash
      #                    (<tt>-</tt><tt>-</tt>)
      # +help_banner+::    Defines a banner for the help message (<em>unused</em>)
      # +istream+::        Defines an input stream to use
      # +name+::           Defines the name of the application
      # +ostream+::        Defines an output stream to use
      # +raise_errors+::   If true, raise errors, otherwise fail gracefully
      #
      # Example:
      #
      #  set :name, 'My App'
      #  set :autorun, false
      def set(setting, value)
        @settings[setting.to_sym] = value
      end

      # Displays a throbber while the given block is executed
      #
      # Example:
      #
      #  action 'slow' do
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

      private

      # Assigns aliases to the actions that have been defined using action_alias
      #
      # Clears the aliases Hash afterwards
      def assign_aliases
        @aliases.each do |key, action|
          if @settings[:dashed_options]
            action = "--#{action}".to_sym
            key = "--#{key}".to_sym
          end

          unless @actions.key? key
            @actions[key] = @actions[action]
          else
            warn "There's already an action called \"#{key}\"."
          end
        end
      end

      # Defines an action for enabling debug mode
      def debug_action
        action 'debug', { :description => 'Enable debug mode' } do
          $DEBUG = true
        end
      end

      # Defines an action for displaying a help screen
      #
      # This takes any defined action and it's corresponding options and
      # descriptions and displays them in a user-friendly manner.
      def help_action
        action 'help', { :description => 'Display this help screen' } do
          help = {}
          @actions.each do |option, action|
            help[action] = [] if help[action].nil?
            help[action] << option.to_s
          end

          put @settings[:help_banner]
          puts " [options]" unless @default.nil?
          puts ''

          help.each do |action, options|
            help[action] = options.sort.join(', ')
          end
          max_options_length = help.values.max { |a,b| a.size <=> b.size }.size
          help.sort_by { |action, options| options }.each do |action, options|
            puts options.ljust(max_options_length) << "    " << action.description
          end
        end
      end

      # Hide output inside the given block and print it after the block has
      # finished
      #
      # +block+:: The block that should not print output while it's running
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
        debug_action
        help_action
        verbose_action
        assign_aliases
        @initialized = true
      end

      # Parses the options used when starting the application
      #
      # +options+:: An Array of Strings that should be used as application
      #             options. Usually +ARGV+ is used for this.
      def parse_options(options)
        actions_to_call = {}
        last_action     = nil

        options.each do |option|
          option_sym = option.to_s.to_sym
          if @actions.keys.include? option_sym
            actions_to_call[option_sym] = []
            last_action = option_sym
          elsif last_action.nil? || (option.is_a?(String) && @settings[:dashed_options] && option[0..1] == '--')
            raise UnknownOptionError.new(option)
          else
            actions_to_call[last_action] << option
          end
        end

        actions_to_call
      end

      # Defines an action for enabling verbose output
      def verbose_action
        action 'verbose', { :description => 'Enable verbose output' } do
          $VERBOSE = true
        end
      end

    end

  end

end
