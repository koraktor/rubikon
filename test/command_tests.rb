# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'test_helper'

class DummyApp < Application::Base

  set :autorun, false

end

class CommandTests < Test::Unit::TestCase

  context 'A Rubikon command' do

    setup do
      @app = DummyApp.instance
    end

    should 'raise an exception when no appliation is given' do
      assert_raise ArgumentError do
        Command.new nil, 'command'
      end
    end

    should 'raise an exception when no code block is given' do
      assert_raise BlockMissingError do
        Command.new @app, 'command'
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

  end

end
