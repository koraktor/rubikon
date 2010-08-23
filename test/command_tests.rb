# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'test_helper'

class DummyApp < Application::Base

  set :autorun, false

  attr_accessor :external_command_run

end

class CommandTests < Test::Unit::TestCase

  context 'A Rubikon command' do

    setup do
      @app = DummyApp.instance
      @app.instance_eval do
        @path = File.dirname(__FILE__)
      end
    end

    should 'be a Parameter' do
      assert Command.included_modules.include? Parameter
      assert Command.new(@app, :command){}.is_a? Parameter
    end

    should 'raise an exception when no appliation is given' do
      assert_raise ArgumentError do
        Command.new nil, :command
      end
    end

    should 'raise an exception when no code block is given' do
      assert_raise BlockMissingError do
        Command.new @app, :command
      end
    end

    should 'not raise an exception when created with correct options' do
      description = 'This is a command'
      name        = :command
      assert_nothing_raised do
        command = Command.new @app, name do end
        command.description = description
        assert_equal name, command.name
        assert_equal description, command.description
      end
    end

    should 'correctly parse given parameters' do
      command = Command.new @app, :command do end
      flag = Flag.new(:test)
      command << flag
      assert_raise UnknownParameterError do
        command.run(*%w{--test --unknown})
      end
      assert flag.active?
    end

    should 'run the code supplied inside its block' do
      block_run = false
      command = Command.new @app, :command do
        block_run = true
      end
      command.run
      assert block_run
    end

    should 'run external code if no block is given' do
      @app.external_command_run = false
      command = Command.new @app, :external_command
      command.run
      assert @app.external_command_run
    end

  end

end
