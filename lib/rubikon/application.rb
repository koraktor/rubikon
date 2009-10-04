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

  class Application

    include Singleton

    def set(setting, value)
      @settings[setting.to_sym] = value
    end

    def initialize
      @actions  = {}
      @default  = nil
      @settings = {}
      @settings[:dashed_options] = true
      @settings[:help_banner]    = "Usage: #{$0}"
      @settings[:name]           = self.class.to_s
    end

    # Run this application
    def run(args = ARGV)
      begin
        action_results = []

        if !@default.nil? and args.empty?
          action_results << @default.run
        else
          parse_args(args).each do |action, args|
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

    def self.method_missing(method_name, *args, &block)
      instance.send(method_name, *args, &block)
    end

    def action(name, options = {}, &block)
      raise "No block given" unless block_given?

      key = name
      key = "--#{key}" if @settings[:dashed_options]

      @actions[key.to_sym] = Action.new(name, options, block)
    end

    def default(options = {}, &block)
      @default = Action.new(:default, options, block)
    end

    def parse_args(args)
      actions_to_call = {}
      last_action     = nil

      args.each do |arg|
        arg_sym = arg.to_sym
        if @actions.keys.include? arg_sym
          actions_to_call[arg_sym] = []
          last_action = arg_sym
        elsif last_action.nil?
          raise UnknownArgumentError.new(arg)
        else
          actions_to_call[last_action] << arg
        end
      end

      actions_to_call
    end

  end

end
