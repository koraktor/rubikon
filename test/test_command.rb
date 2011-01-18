# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'test_parameter'

class TestCommand < Test::Unit::TestCase

  include TestParameter

  context 'A Rubikon command' do

    should 'be a Parameter with arguments' do
      assert Command.included_modules.include?(Parameter)
      assert Command.included_modules.include?(HasArguments)
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

    should 'run the code supplied inside its block' do
      block_run = false
      command = Command.new @app, :command do
        block_run = true
      end
      command.send :run
      assert block_run
    end

    should 'run external code if no block is given' do
      command = Command.new @app, :external_command
      command.send :run
      assert @app.sandbox.instance_variable_get(:@external_command_run)
    end

  end

end
