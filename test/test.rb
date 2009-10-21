# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'rubygems'
require 'shoulda'
require 'tempfile'

begin require 'redgreen'; rescue LoadError; end

require File.join(File.dirname(__FILE__), '..', 'lib', 'rubikon')

class RubikonTestApp < Rubikon::Application

  set :autorun, false
  set :name, 'Rubikon test application'
  set :raise_errors, true

  default do
    'default action'
  end

  action 'input' do
    input 'input'
  end

  action 'object_id' do
    object_id
  end

  action 'noarg' do
    'noarg action'
  end

  action 'realnoarg' do ||
  end

  action 'noarg2' do
  end

  action 'number_string', :param_type => [Numeric, String] do |s,n|
  end

  action 'string', :param_type => String do |s|
  end

  action 'required' do |what|
    "required argument was #{what}"
  end

end

class RubikonTests < Test::Unit::TestCase

  context 'A Rubikon application\'s class' do

    setup do
      @app = RubikonTestApp.instance
    end

    should 'run it\'s instance for called methods' do
      assert_equal @app.run(%w{--object_id}), RubikonTestApp.run(%w{--object_id})
    end
  end

  context 'A Rubikon application' do

    setup do
      @app = RubikonTestApp
    end

    should 'be a singleton' do
      assert_raise NoMethodError do
        RubikonTestApp.new.object_id
      end
    end

    should 'run it\'s default action without options' do
      result = RubikonTestApp.run
      assert_equal 1, result.size
      assert_equal 'default action', result.first
    end

    should 'run with a mandatory option' do
      result = RubikonTestApp.run(%w{--required arg})
      assert_equal 1, result.size
      assert_equal 'required argument was arg', result.first
    end

    should 'not run without a mandatory argument' do
      assert_raise Rubikon::MissingArgumentError do
        RubikonTestApp.run(%w{--required})
      end
    end

    should 'require an argument type if it has been defined' do
      assert_raise TypeError do
        RubikonTestApp.run(['--string', 6])
      end
      assert_raise TypeError do
        RubikonTestApp.run(['--number_string', 6, 6])
      end
      assert_raise TypeError do
        RubikonTestApp.run(['--number_string', 'test' , 6])
      end
    end

    should 'raise an exception when calling an action with the wrong number of
            arguments' do
      assert_raise Rubikon::MissingArgumentError do
        RubikonTestApp.run(%w{--string})
      end
      assert_raise ArgumentError do
        RubikonTestApp.run(%w{--string}, 'test', 3)
      end
    end

    should 'raise an exception when using an unknown option' do
      assert_raise Rubikon::UnknownOptionError do
        RubikonTestApp.run(%w{--unknown})
      end
      assert_raise Rubikon::UnknownOptionError do
        RubikonTestApp.run(%w{--noarg --unknown})
      end
      assert_raise Rubikon::UnknownOptionError do
        RubikonTestApp.run(%w{--unknown --noarg})
      end
    end

    should 'be able to handle user input' do
      @istream = Tempfile.new 'rubikon_test_istream'
      @ostream = Tempfile.new 'rubikon_test_ostream'
      RubikonTestApp.set :istream, @istream
      RubikonTestApp.set :ostream, @ostream

      input_string = 'test'
      @istream << input_string + "\n"
      @istream.rewind
      assert_equal [input_string], RubikonTestApp.run(%w{--input})
      @ostream.rewind
      assert_equal 'input: ', @ostream.gets
      @istream.delete
      @ostream.delete
    end

  end

  context 'A Rubikon action' do

    should 'throw an exception when no code block is given' do
      assert_raise Rubikon::BlockMissingError do
        Rubikon::Action.new 'name'
      end
      assert_raise Rubikon::BlockMissingError do
        Rubikon::Action.new 'name', {}
      end
    end

    should 'not raise an exception when created without options' do
      action_name = 'someaction'
      action_options = {
        :description => 'this is an action',
        :param_type  => String
      }
      assert_nothing_raised do
        action = Rubikon::Action.new action_name, action_options do end
        assert_equal action_name, action.name
        assert_equal action_options[:description], action.description
        assert_equal action_options[:param_type], action.param_type
      end
    end

  end

end
