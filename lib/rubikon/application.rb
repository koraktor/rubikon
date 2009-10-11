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

  # The main class of Rubikon
  class Application

    include Singleton

    # Sets an application setting
    def set(setting, value)
      @settings[setting.to_sym] = value
    end

    # Initialize with default settings
    def initialize
      @actions  = {}
      @default  = nil
      @settings = {
        :dashed_options => true,
        :help_banner    => "Usage: #{$0}",
        :istream        => $stdin,
        :name           => self.class.to_s,
        :ostream        => $stdout,
        :raise_errors   => false
      }
    end

    # Output a line of text using IO#puts of the output stream
    def puts(text)
      @settings[:ostream].puts text
    end

    # Run this application
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
        raise $! if @settings[:raise_errors]
        exit 1
      end

      action_results
    end

    private

    # This is used for convinience. Method calls on the class itself are
    # relayed to the singleton instance
    def self.method_missing(method_name, *args, &block)
      instance.send(method_name, *args, &block)
    end

    # Relay puts to the instance method
    def self.puts(text)
      instance.puts text
    end

    # Define an application action
    def action(name, options = {}, &block)
      raise "No block given" unless block_given?

      key = name
      key = "--#{key}" if @settings[:dashed_options]

      @actions[key.to_sym] = Action.new(name, options, block)
    end

    # Define the default action of the application
    def default(options = {}, &block)
      @default = Action.new(:default, options, block)
    end

    def input(prompt = '')
      unless prompt.empty?
        @settings[:ostream] << "#{prompt}: "
      end
      @settings[:istream].gets
    end

    # Parses the options used when starting the application
    def parse_options(options)
      actions_to_call = {}
      last_action     = nil

      options.each do |option|
        option_sym = option.to_sym
        if @actions.keys.include? option_sym
          actions_to_call[option_sym] = []
          last_action = option_sym
        elsif last_action.nil?
          raise UnknownOptionError.new(option)
        else
          actions_to_call[last_action] << option
        end
      end

      actions_to_call
    end

  end

end
