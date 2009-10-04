#!/usr/bin/env ruby
#
# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'rubygems'
require 'shoulda'

begin require 'redgreen' rescue LoadError end

require File.join(File.dirname(__FILE__), '..', 'lib', 'rubikon')

class RubikonTestApp < Rubikon::Application

  set :name, 'Rubikon test application'

  set :raise_errors, true

  default do
    'default action'
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

    should 'run it\'s default action without arguments' do
      assert_equal 'default action', RubikonTestApp.run
    end

    should 'run with a mandatory argument' do
      result = RubikonTestApp.run(%w{--required arg})
      assert_equal result.size, 1
      assert_equal 'required argument was arg', result.first
    end

    should "don't run without a mandatory argument" do
      assert_raise Rubikon::MissingArgument do
        RubikonTestApp.run(%w{--required})
      end
    end

    should "require an argument type if it has been defined" do
      assert_raise TypeError do
        RubikonTestApp.run(['--string', 6])
      end
    end

  end

end
