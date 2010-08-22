# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rubikon/command'
require 'rubikon/exceptions'
require 'rubikon/flag'
require 'rubikon/progress_bar'
require 'rubikon/throbber'

module Rubikon

  module Application

    module InstanceMethods


      # Initialize with default settings (see set for more detail)
      #
      # If you really need to override this in your application class, be sure
      # to call +super+
      def initialize
        @commands    = {}
        @initialized = false
        @parameters  = []
        @settings    = {
          :autorun        => true,
          :help_banner    => "Usage: #{$0}",
          :istream        => $stdin,
          :name           => self.class.to_s,
          :ostream        => $stdout,
          :raise_errors   => false
        }
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
      # Calling this method explicitly is not required when you want to create
      # a simple application (having one main class inheriting from
      # Rubikon::Application). But it's useful for testing or if you want to
      # havesome sort of sub-applications.
      def run(args = ARGV)
        begin
          init unless @initialized

          command_arg = args.shift
          if command_arg.nil? || command_arg.start_with?('-')
            command = @commands[:__default]
            args.unshift(command_arg) unless command_arg.nil?
            raise NoDefaultCommandError if command.nil?
          else
            command = @commands[command_arg.to_sym]
            raise UnknownCommandError.new(command_arg) if command.nil?
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

      # Sets an application setting
      #
      # +setting+:: The name of the setting to change, will be symbolized
      #             first.
      # +value+::   The value the setting should be changed to
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

      private

      # Define a new application Command or an alias to an existing one
      #
      # +name+::        The name of the Command as used in application
      #                 parameters. This might also be a Hash where every key
      #                 will be an alias to the corresponding value, e.g.
      #                 <tt>{ :alias => :command }</tt>.
      # +description+:: A description for this Command for use in the
      #                 application's help screen (default: +nil+)
      # +block+::       A block that contains the code that should be executed
      #                 when this Command is called, i.e. when the application
      #                 is called with the associated parameter
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
          @commands[name] = command
        end

        unless @parameters.empty?
          @parameters.each do |parameter|
            command << parameter
          end
          @parameters.clear
        end
      end

      # Define the default Command of the application, i.e. the Command that is
      # called if no matching Command parameter can be found
      #
      # +description+:: A description for this Command for use in the
      #                 application's help screen (default: +nil+)
      # +block+::       A block that contains the code that should be executed
      #                 when this Command is called, i.e. when no Command
      #                 parameter is given to the application
      def default(description = nil, &block)
        command(:__default, description, &block)
      end

      # Create a new Flag with the given name for the next Command
      #
      # +name+:: The name of the Flag (without dashes). Dashes will be
      #          automatically added (+-+ for single-character flags, +--+ for
      #          other flags). This might also be a Hash where every key will
      #          be an alias to the corresponding value, e.g.
      #          <tt>{ :alias => :flag }</tt>.
      #
      # Example:
      #
      #   flag :status
      #   flag :st => :status
      #   command :something do
      #     ...
      #   end
      #
      def flag(name)
        if name.is_a? Hash
          @parameters << name
        else
          @parameters << Flag.new(name.to_s)
        end
      end

      # Checks whether parameter with the given name has been supplied by the
      # user on the command-line.
      #
      # Example:
      #
      #  flag :status
      #  command :something do
      #    print_status if given? :status
      #  end
      def given?(name)
        parameter = @current_command.parameters[name]
        return false if parameter.nil?
        parameter.active?
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
        @commands.each do |name, command|
          if command.is_a? Symbol
            command = @commands[command]
            if command.is_a? Command
              @commands[name] = command
            end
          end
        end

        @initialized = true
      end

    end

  end

end
