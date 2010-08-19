# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'test_helper'
require 'testapp'

class ApplicationTests < Test::Unit::TestCase

  context 'A Rubikon application\'s class' do

    setup do
      @app = RubikonTestApp.instance
    end

    should 'be a singleton' do
      assert_raise NoMethodError do
        RubikonTestApp.new
      end
    end

    should 'run it\'s instance for called methods' do
      assert_equal @app.run(%w{object_id}), RubikonTestApp.run(%w{object_id})
    end

  end

  context 'A Rubikon application' do

    setup do
      @app = RubikonTestApp
      @ostream = StringIO.new
      @app.set :ostream, @ostream
    end

    should 'exit gracefully' do
      unknown = 'unknown'
      @app.set :raise_errors, false
      begin
        @app.run([unknown])
      rescue Exception => e
      end
      assert_instance_of SystemExit, e
      assert_equal 1, e.status
      @ostream.rewind
      assert_equal "Error:\n", @ostream.gets
      assert_equal "    Unknown command: #{unknown}\n", @ostream.gets
      @app.set :raise_errors, true
    end

    should 'run it\'s default action without options' do
      assert_equal 'default command', @app.run([])
    end

    should 'raise an exception when using an unknown command' do
      assert_raise UnknownCommandError do
        @app.run(%w{unknown})
      end
    end

    should 'be able to handle user input' do
      @istream = StringIO.new
      @app.set :istream, @istream

      input_string = 'test'
      @istream.puts input_string
      @istream.rewind
      assert_equal input_string, @app.run(%w{input})
      @ostream.rewind
      assert_equal 'input: ', @ostream.gets
    end

    should "don't break output while displaying a throbber or progress bar" do
      @app.run(%w{throbber})
      assert_equal " \b-\b\\\b|\b/\bdon't\nbreak\n", @ostream.string
      @ostream.rewind

      @app.run(%w{progressbar})
      assert_equal "#" * 20 << "\n" << "test\n" * 4, @ostream.string
    end

    should 'have working command aliases' do
      assert_equal @app.run(%w{alias_before}), @app.run(%w{object_id})
      assert_equal @app.run(%w{alias_after}), @app.run(%w{object_id})
    end

  end

end
