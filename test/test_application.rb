# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2011, Sebastian Staudt

require 'helper'
require 'testapps'

class TestApplication < Test::Unit::TestCase

  context 'A Rubikon application\'s class' do

    setup do
      @app = TestApp.instance
    end

    should 'be a singleton' do
      assert_raise NoMethodError do
        TestApp.new
      end
    end

    should 'run it\'s instance for called methods' do
      assert_equal @app.run(%w{object_id}), TestApp.run(%w{object_id})
    end

  end

  context 'A Rubikon application' do

    setup do
      @app = TestApp
      @estream = StringIO.new
      @ostream = StringIO.new
      @app.set :estream, @estream
      @app.set :ostream, @ostream
      @app.set :raise_errors, true
    end

    should 'exit gracefully' do
      @app.set :raise_errors, false
      begin
        @app.run(%w{unknown})
      rescue Exception => e
        assert_instance_of SystemExit, e
        assert_equal 1, e.status
      end
      assert_match /(?:\e\[0;31m)?Error:(?:\e\[0m)?\n/, @estream.gets
      assert_equal "    Unknown command: unknown\n", @estream.gets
    end

    should 'run its default command without arguments' do
      assert_equal 'default command', @app.run([])
    end

    should 'raise an exception when using an unknown command' do
      assert_raise UnknownCommandError do
        @app.run(%w{unknown})
      end
    end

    should 'raise an exception when run without arguments without default' do
      assert_raise NoDefaultCommandError do
        TestAppWithoutDefault.run([])
      end
    end

    should 'be able to handle user input' do
      @istream = StringIO.new
      @app.set :istream, @istream

      @istream.puts "test\ntest\nx\n"
      @istream.rewind

      assert_equal %w{test x}, @app.run(%w{input})
      assert_equal 'input: validated [x]: Please provide valid input [x]: ', @ostream.gets
    end

    should 'not break output while displaying a throbber or progress bar' do
      @app.run(%w{throbber})
      assert_match (/ \x08(?:(?:-|\\|\/|\|)\x08){4,}don't\nbreak\n/), @ostream.string
      @app.run(%w{progressbar})
      assert_equal "#" * 20 << "\n" << "test\n" * 4, @ostream.string
    end

    should 'have working command aliases' do
      assert_equal @app.run(%w{alias_before}), @app.run(%w{object_id})
      assert_equal @app.run(%w{alias_after}), @app.run(%w{object_id})
    end

    should 'have a global debug flag' do
      @app.run(%w{--debug})
      assert $DEBUG
      $DEBUG = false
      @app.run(%w{-d})
      assert $DEBUG
      $DEBUG = false
    end

    should 'have a global verbose flag' do
      @app.run(%w{--verbose})
      assert $VERBOSE
      $VERBOSE = false
      @app.run(%w{-v})
      assert $VERBOSE
      $VERBOSE = false
    end

    should 'have working global parameters' do
      assert_equal 'flag', @app.run(%w{globalopt --gflag})
      assert_equal 'flag', @app.run(%w{globalopt --gf1})
      assert_equal 'flag', @app.run(%w{globalopt --gf2})
      assert_equal 'test', @app.run(%w{globalopt --gopt test})
      assert_equal 'test', @app.run(%w{globalopt --go1 test})
      assert_equal 'test', @app.run(%w{globalopt --go2 test})
    end

    should 'have a working help command' do
      @app.run(%w{help})
      assert_match /Usage: [^ ]* \[--debug\|-d\] \[--gflag\|--gf1\|--gf2\] \[--gopt\|--go1\|--go2 \.\.\.\] \[--verbose\|-v\] \[command\] \[args\]\n\nCommands:\n  arguments      \n  globalopt      \n  help           Show help for the application or a single command\n  input          \n  object_id      \n  parameters     \n  progressbar    \n  sandbox        \n  throbber       \n/, @ostream.string
    end

    should 'have a working DSL for command parameters' do
      params = @app.run(%w{parameters}).values.uniq.sort { |a,b| a.name.to_s <=> b.name.to_s }
      assert_equal :flag, params[0].name
      assert_equal [:f], params[0].aliases
      assert !params[0].active?
      assert_equal :option, params[1].name
      assert_equal [:o], params[1].aliases
      assert !params[1].active?
    end

    should 'allow simplified access to arguments' do
      result = @app.run(%w{arguments cmd_test --arg opt_test})
      assert_equal %w{opt_test opt_test cmd_test}, result
    end

    should 'be protected by a sandbox' do
      %w{init parse_arguments run}.each do |method|
        assert_raise NoMethodError do
          @app.run(['sandbox', method])
        end
      end
    end

    should 'know its file system location' do
      dir = File.expand_path(File.dirname(__FILE__))
      assert_equal dir + '/testapps.rb', @app.base_file
      assert_equal dir, @app.path
    end

    should 'have working hooks' do
      TestAppWithHooks.set :ostream, @ostream
      TestAppWithHooks.run(%w{execute})

      assert_equal "pre init\npost init\npre execute\nexecute\npost execute\n", @ostream.string
    end

    should 'allow combining single character parameters' do
      @app.run(%w{-dv})
      assert $DEBUG
      assert $VERBOSE
      $DEBUG = false
      $VERBOSE = false
    end

    should 'parse arguments correctly' do
      global_params, cmd, cmd_params = @app.parse_arguments(%w{})
      assert_equal [], global_params
      assert_instance_of Command, cmd
      assert_equal cmd.name, :__default
      assert_equal [], cmd_params

      global_params, cmd, cmd_params = @app.parse_arguments(%w{-d -v})
      assert_instance_of Array, global_params
      assert_equal 2, global_params.size
      assert_instance_of Flag, global_params[0]
      assert_equal :debug, global_params[0].name
      assert_instance_of Flag, global_params[1]
      assert_equal :verbose, global_params[1].name
      assert_instance_of Command, cmd
      assert_equal cmd.name, :__default
      assert_equal [], cmd_params

      global_params, cmd, cmd_params = @app.parse_arguments(%w{-dv})
      assert_instance_of Array, global_params
      assert_equal 2, global_params.size
      assert_instance_of Flag, global_params[0]
      assert_equal :debug, global_params[0].name
      assert_instance_of Flag, global_params[1]
      assert_equal :verbose, global_params[1].name
      assert_instance_of Command, cmd
      assert_equal cmd.name, :__default
      assert_equal [], cmd_params

      global_params, cmd, cmd_params = @app.parse_arguments(%w{-d -v object_id})
      assert_instance_of Array, global_params
      assert_equal 2, global_params.size
      assert_instance_of Flag, global_params[0]
      assert_equal :debug, global_params[0].name
      assert_instance_of Flag, global_params[1]
      assert_equal :verbose, global_params[1].name
      assert_instance_of Command, cmd
      assert_equal cmd.name, :object_id
      assert_equal [], cmd_params

      global_params, cmd, cmd_params = @app.parse_arguments(%w{-d sandbox --gopt test puts})
      assert_instance_of Array, global_params
      assert_equal 2, global_params.size
      assert_instance_of Flag, global_params[0]
      assert_equal :debug, global_params[0].name
      assert_instance_of Option, global_params[1]
      assert_equal :gopt, global_params[1].name
      assert_equal %w{test}, global_params[1].args
      assert_instance_of Command, cmd
      assert_equal cmd.name, :sandbox
      assert_equal %w{puts}, cmd.args
      assert_equal [], cmd_params

      assert_raise UnknownParameterError do
        @app.parse_arguments(%w{-x})
      end
    end

  end

end
