# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'singleton'
require 'yaml'

require 'rubikon/action'
require 'rubikon/exceptions'

module Rubikon

  version = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', 'VERSION.yml'))
  VERSION = "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"

  # The main class of Rubikon. Let your own application class inherit from this
  # one.
  class Application

    include Singleton

    attr_reader :settings

    # Returns whether this application should be ran automatically
    def self.autorun?
      instance.settings[:autorun] || false
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
    def set(setting, value)
      @settings[setting.to_sym] = value
    end

    # Initialize with default settings (see set for more detail)
    def initialize
      @actions  = {}
      @default  = nil
      @settings = {
        :autorun        => true,
        :dashed_options => true,
        :help_banner    => "Usage: #{$0}",
        :istream        => $stdin,
        :name           => self.class.to_s,
        :ostream        => $stdout,
        :raise_errors   => false
      }
    end

    # Output text using +IO#<<+ of the output stream
    #
    # +text+:: The text to write into the output stream
    def put(text)
      ostream << text
      ostream.flush
    end

    # Output a character using +IO#putc+ of the output stream
    #
    # +char+:: The character to write into the output stream
    def putc(char)
      ostream.putc char
    end

    # Output a line of text using +IO#puts+ of the output stream
    #
    # +text+:: The text to write into the output stream
    def puts(text)
      ostream.puts text
    end

    # Run this application
    #
    # +args+:: The command line arguments that should be given to the
    #          application as options
    def run(args = ARGV)
      begin
        action_results = []

        if !@default.nil? and args.empty?
          action_results << @default.run
        else
          parse_options(args).each do |action, args|
            action_results << @actions[action].run(*args)
          end
        end
      rescue
        if @settings[:raise_errors]
          raise $!
        else
          puts "Error:\n    #{$!.message}"
          puts "    #{$!.backtrace.join("\n    ")}" if $DEBUG
          exit 1
        end
      end

      action_results
    end

    private

    # Enables autorun functionality using <tt>Kernel#at_exit</tt>
    #
    # +subclass+:: The subclass inheriting from Application. This is the user's
    #              application.
    #
    # <em>This is called automatically when subclassing Application.</em>
    def self.inherited(subclass)
      Singleton.__init__(subclass)
      at_exit { subclass.run if subclass.autorun? }
    end

    # This is used for convinience. Method calls on the class itself are
    # relayed to the singleton instance.
    #
    # +method_name+:: The name of the method being called
    # +args+::        Any arguments that are given to the method
    # +block+::       A block that may be given to the method
    #
    # <em>This is called automatically when calling methods on the class.</em>
    def self.method_missing(method_name, *args, &block)
      instance.send(method_name, *args, &block)
    end

    # Relay putc to the instance method
    #
    # This is used to hide <tt>Kernel#putc</tt> so that the Application's output IO
    # object is used for printing text
    #
    # +text+:: The text to write into the output stream
    def self.putc(text)
      instance.putc text
    end

    # Relay puts to the instance method
    #
    # This is used to hide <tt>Kernel#puts</tt> so that the Application's output IO
    # object is used for printing text
    #
    # +text+:: The text to write into the output stream
    def self.puts(text)
      instance.puts text
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
      raise "No block given" unless block_given?

      key = name
      key = "--#{key}" if @settings[:dashed_options]

      @actions[key.to_sym] = Action.new(name, options, &block)
    end

    # Define the default Action of the Application
    #
    # +options+:: A Hash of options to be used on the created Action
    #             (default: <tt>{}</tt>)
    # +block+::   A block containing the code that should be executed when this
    #             Action is called, i.e. when no option is given to the
    #             Application
    def default(options = {}, &block)
      @default = Action.new(:default, options, &block)
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

    # Parses the options used when starting the application
    #
    # +options+:: An Array of Strings that should be used as application
    #             options. Usually +ARGV+ is used for this.
    def parse_options(options)
      actions_to_call = {}
      last_action     = nil

      options.each do |option|
        option_sym = option.to_sym
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

    # Convenience method for accessing the user-defined output stream
    def ostream
      @settings[:ostream]
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
    #
    # <em>At the moment using output in the +block+ is not recommended as it
    # will break the throbber</em>
    def throbber(&block)
      spinner = '-\|/'

      code_thread = Thread.new { block.call }

      throbber_thread = Thread.new {
        i = 0
        putc 32
        while code_thread.alive?
          putc 8
          putc spinner[i]
          ostream.flush
          i = (i + 1) % 4
          sleep 0.25
        end
        putc 8
      }

      code_thread.join
      throbber_thread.join
    end

  end

end
