# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'test_helper'

module HasArgumentExtension
  attr_reader :arg_names
end

class TestHasArguments < Test::Unit::TestCase

  context 'A parameter with arguments' do

    setup do
      @has_arg = Object.new
      @has_arg.extend HasArguments
      @has_arg.extend HasArgumentExtension
      @has_arg.instance_eval { @args = [] }
    end

    should 'allow a Numeric as argument count' do
      @has_arg.arg_count = 1
      assert_equal 1..1, @has_arg.arg_count
      assert_nil @has_arg.arg_names
    end

    should 'allow a Range as argument count' do
      @has_arg.arg_count = 1..3
      assert_equal 1..3, @has_arg.arg_count
      assert_nil @has_arg.arg_names
    end

    should 'allow an Array as argument count' do
      @has_arg.arg_count = [2, 5, 6]
      assert_equal 2..6, @has_arg.arg_count
      assert_nil @has_arg.arg_names
    end

    should 'allow a Symbol Array as argument names' do
      @has_arg.arg_count = [:arg1, :arg2, :arg3]
      assert_equal 3..3, @has_arg.arg_count
      assert_equal [:arg1, :arg2, :arg3], @has_arg.arg_names
    end

    should 'only have required arguments if argument count is > 0' do
      @has_arg.arg_count = 2
      assert !@has_arg.args_full?
      assert @has_arg.more_args?
      @has_arg << 'argument'
      assert_equal %w{argument}, @has_arg.args
      assert_raise MissingArgumentError do
        @has_arg.check_args
      end
      @has_arg << 'argument'
      assert @has_arg.args_full?
      assert !@has_arg.more_args?
      assert_equal %w{argument argument}, @has_arg.args
      assert_raise ExtraArgumentError do
        @has_arg << 'argument'
      end
      assert_equal %w{argument argument}, @has_arg.args
    end

    should 'have required and optional arguments if argument count is < 0' do
      @has_arg.arg_count = -1
      assert !@has_arg.args_full?
      assert @has_arg.more_args?
      assert_raise MissingArgumentError do
        @has_arg.check_args
      end
      @has_arg << 'argument'
      assert @has_arg.args_full?
      assert @has_arg.more_args?
      assert_equal %w{argument}, @has_arg.args
    end

    should 'only have optional arguments if argument count is 0' do
      @has_arg.arg_count = 0
      assert @has_arg.args_full?
      assert @has_arg.more_args?
      @has_arg << 'argument'
      assert_equal %w{argument}, @has_arg.args
    end

    should 'provide named arguments' do
      @has_arg.arg_count = [:named]
      @has_arg << 'argument'
      assert_equal 'argument', @has_arg[:named]
    end

  end

end
