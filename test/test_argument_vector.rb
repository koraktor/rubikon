# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'helper'
require 'testapps'

class TestArgumentVector < Test::Unit::TestCase

  context 'An argument vector' do

    setup do
      @app = TestApp.instance
      @argv = []
      @argv.extend ArgumentVector
    end

    should 'expand arguments correctly' do
      @argv.expand!
      assert @argv.empty?

      @argv.replace %w{command --param arg}
      @argv.expand!
      assert_equal %w{command --param arg}, @argv

      @argv.replace %w{command -pq arg}
      @argv.expand!
      assert_equal %w{command -p -q arg}, @argv

      @argv.replace %w{command -pp arg}
      @argv.expand!
      assert_equal %w{command -p arg}, @argv

      @argv.replace %w{command --param=arg}
      @argv.expand!
      assert_equal %w{command --param arg}, @argv

      @argv.replace %w{command -pq --param=arg}
      @argv.expand!
      assert_equal %w{command -p -q --param arg}, @argv
    end

    should 'select the command correctly' do
      assert_equal [nil, 0], @argv.command!(TestAppWithoutDefault.instance.commands)
      assert @argv.empty?

      command, pos = @argv.command!(@app.commands)
      assert_equal :__default, command.name
      assert_equal 0, pos
      assert @argv.empty?

      @argv.replace %w{unknown}
      assert_equal [nil, 0], @argv.command!(TestAppWithoutDefault.instance.commands)
      assert_equal %w{unknown}, @argv

      @argv.replace %w{input}
      command, pos = @argv.command!(@app.commands)
      assert_equal :input, command.name
      assert_equal 0, pos
      assert @argv.empty?

      @argv.replace %w{--debug input}
      command, pos = @argv.command!(@app.commands)
      assert_equal :input, command.name
      assert_equal 1, pos
      assert_equal %w{--debug}, @argv

      @argv.replace %w{--debug input input}
      command, pos = @argv.command!(@app.commands)
      assert_equal :input, command.name
      assert_equal 1, pos
      assert_equal %w{--debug input}, @argv

      @argv.replace %w{--debug -- input}
      command, pos = @argv.command!(@app.commands)
      assert_equal :__default, command.name
      assert_equal 0, pos
      assert_equal %w{--debug input}, @argv
    end

    should 'parse parameters correctly' do
      assert @argv.params!(@app.global_parameters).empty?
      assert @argv.empty?

      @argv.replace %w{--gopt}
      params = @argv.params!(@app.global_parameters)
      assert_equal 1, params.size
      assert_equal :gopt, params.first.name
      assert @argv.empty?

      @argv.replace %w{dummy --gopt}
      params = @argv.params!(@app.global_parameters, 1)
      assert_equal 1, params.size
      assert_equal :gopt, params.first.name
      assert_equal %w{dummy}, @argv

      @argv.replace %w{--gopt arg}
      params = @argv.params!(@app.global_parameters)
      assert_equal 1, params.size
      assert_equal :gopt, params.first.name
      assert_equal %w{arg}, params.first.args
      assert @argv.empty?

      @app.global_parameters[:gopt].send :reset

      @argv.replace %w{--gopt arg --gflag}
      params = @argv.params!(@app.global_parameters)
      assert_equal 2, params.size
      assert_equal :gopt, params.first.name
      assert_equal %w{arg}, params.first.args
      assert_equal :gflag, params.last.name
      assert @argv.empty?
    end

    should 'parse arguments correctly' do
      gopt = @app.global_parameters[:gopt]

      @argv.scoped_args!(gopt)
      assert gopt.args.empty?
      assert @argv.empty?

      @argv.replace %w{arg}
      @argv.scoped_args!(gopt)
      assert_equal %w{arg}, gopt.args
      assert @argv.empty?

      gopt.send :reset

      @argv.replace %w{arg1 arg2}
      @argv.scoped_args!(gopt)
      assert_equal %w{arg1}, gopt.args
      assert_equal %w{arg2}, @argv

      gopt.send :reset

      @argv.replace %w{--gflag arg}
      @argv.scoped_args!(gopt)
      assert gopt.args.empty?
      assert_equal %w{--gflag arg}, @argv

      gopt.send :reset

      @argv.replace %w{--gflag arg}
      @argv.scoped_args!(gopt, 1)
      assert_equal %w{arg}, gopt.args
      assert_equal %w{--gflag}, @argv
    end

    teardown do
      @app.send :reset
    end

  end

end
