# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'test_helper'

class FlagTests < Test::Unit::TestCase

  context 'A Rubikon option' do

    should 'be a Parameter' do
      assert Option.included_modules.include? Parameter
      assert Option.new(:test).is_a? Parameter
    end

    should 'call its code block if it is activated' do
      block_run = false
      option = Option.new :test do
        block_run = true
      end
      option.active!
      assert option.active?
      assert block_run
    end

    should 'have arguments' do
      option = Option.new :test
      assert option.respond_to?(:arg_count)
      assert option.respond_to?(:args)
    end

    should 'only have required arguments if argument count is > 0' do
      option = Option.new :test, 2
      assert !option.args_full?
      assert option.more_args?
      option << 'argument'
      assert_equal %w{argument}, option.args
      assert_raise MissingArgumentError do
        option.check_args
      end
      option << 'argument'
      assert option.args_full?
      assert !option.more_args?
      assert_equal %w{argument argument}, option.args
      assert_raise ExtraArgumentError do
        option << 'argument'
      end
      assert_equal %w{argument argument}, option.args
    end

    should 'have required and optional arguments if argument count is < 0' do
      option = Option.new :test, -1
      assert !option.args_full?
      assert option.more_args?
      assert_raise MissingArgumentError do
        option.check_args
      end
      option << 'argument'
      assert option.args_full?
      assert option.more_args?
      assert_equal %w{argument}, option.args
    end

    should 'only have optional arguments if argument count is 0' do
      option = Option.new :test, 0
      assert option.args_full?
      assert option.more_args?
      option << 'argument'
      assert_equal %w{argument}, option.args
    end

  end

end
