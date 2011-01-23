# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'helper'
require 'test_parameter'

class HasArg
  include HasArguments

  attr_reader :arg_names, :arg_values
  public :<<, :active!, :arg_count, :args_full?, :check_args, :more_args?,
         :reset

  def initialize(*options)
     super DummyApp.instance, 'dummy', *options
  end
end

class TestHasArguments < Test::Unit::TestCase

  context 'A parameter with arguments' do

    should 'allow a Numeric as argument count' do
      has_arg = HasArg.new 1
      assert_equal 1..1, has_arg.arg_count
      assert_equal [], has_arg.arg_names
      assert_equal ({}), has_arg.arg_values
    end

    should 'allow a Range as argument count' do
      has_arg = HasArg.new 1..3
      assert_equal 1..3, has_arg.arg_count
      assert_equal [], has_arg.arg_names
      assert_equal ({}), has_arg.arg_values
    end

    should 'allow a Symbol Array as argument names' do
      has_arg = HasArg.new :arg1, :arg2, :arg3
      assert_equal 3..3, has_arg.arg_count
      assert_equal [:arg1, :arg2, :arg3], has_arg.arg_names
      assert_equal ({}), has_arg.arg_values
    end

    should 'allow a argument validation for normal arguments' do
      has_arg = HasArg.new(:arg1, :arg2 => ['string', /regexp/, :numeric])
      assert_equal 2..2, has_arg.arg_count
      assert_equal [:arg1, :arg2], has_arg.arg_names
      assert_equal 1, has_arg.arg_values.size
      assert_equal /^(?-mix:string|(?-mix:regexp)|(?-mix:-?[0-9]+))$/, has_arg.arg_values[:arg2]

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << 'string'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << 'regexp'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << '123'
        has_arg.check_args
      end
    end

    should 'allow a argument validation for optional arguments' do
      has_arg = HasArg.new(:arg1, :arg2 => [:optional, 'string', /regexp/, :numeric])
      assert_equal 1..2, has_arg.arg_count
      assert_equal [:arg1, :arg2], has_arg.arg_names
      assert_equal 1, has_arg.arg_values.size
      assert_equal /^(?-mix:string|(?-mix:regexp)|(?-mix:-?[0-9]+))$/, has_arg.arg_values[:arg2]

      assert_nothing_raised do
        has_arg << 'test'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << 'string'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << 'regexp'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << '123'
        has_arg.check_args
      end
    end

    should 'allow a argument validation for remainder arguments' do
      has_arg = HasArg.new(:arg1, :arg2 => [:remainder, 'string', /regexp/, :numeric])
      assert_equal 2..-1, has_arg.arg_count
      assert_equal [:arg1, :arg2], has_arg.arg_names
      assert_equal 1, has_arg.arg_values.size
      assert_equal /^(?-mix:string|(?-mix:regexp)|(?-mix:-?[0-9]+))$/, has_arg.arg_values[:arg2]

      assert_raise MissingArgumentError do
        has_arg << 'test'
        has_arg.check_args
      end

      has_arg.reset

      assert_raise UnexpectedArgumentError do
        has_arg << 'test'
        has_arg << 'test'
        has_arg.check_args
      end

      has_arg.reset

      assert_nothing_raised do
        has_arg << 'test'
        has_arg << 'string'
        has_arg << 'regexp'
        has_arg << '123'
        has_arg.check_args
      end
    end

    should 'only have required arguments if argument count is > 0' do
      has_arg = HasArg.new 2
      assert_equal 2..2, has_arg.arg_count
      assert !has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert_equal %w{argument}, has_arg.args
      assert_raise MissingArgumentError do
        has_arg.check_args
      end
      has_arg << 'argument'
      assert has_arg.args_full?
      assert !has_arg.more_args?
      assert_equal %w{argument argument}, has_arg.args
      assert_raise ExtraArgumentError do
        has_arg << 'argument'
      end
      assert_equal %w{argument argument}, has_arg.args
    end

    should 'have required and optional arguments if argument count is < 0' do
      has_arg = HasArg.new -1
      assert_equal 1..-1, has_arg.arg_count
      assert !has_arg.args_full?
      assert has_arg.more_args?
      assert_raise MissingArgumentError do
        has_arg.check_args
      end
      has_arg << 'argument'
      assert has_arg.args_full?
      assert has_arg.more_args?
      assert_equal %w{argument}, has_arg.args
    end

    should 'only have optional arguments if argument count is 0' do
      has_arg = HasArg.new 0
      assert_equal 0..-1, has_arg.arg_count
      assert has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert_equal %w{argument}, has_arg.args
    end

    should 'provide named arguments' do
      has_arg = HasArg.new :named
      assert_equal 1..1, has_arg.arg_count
      has_arg << 'argument'
      assert_equal 'argument', has_arg[:named]
      assert_equal 'argument', has_arg.named
      assert_raise NoMethodError do
        has_arg.not_named
      end
    end

    should 'provide optional named arguments' do
      has_arg = HasArg.new :required, :optional => :optional
      assert_equal 1..2, has_arg.arg_count
      has_arg << 'argument'
      assert has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert !has_arg.more_args?
      assert_equal 'argument', has_arg.required
      assert_equal 'argument', has_arg.optional
    end

    should 'provide named arguments taking all remainding arguments' do
      has_arg = HasArg.new :required, :remainder => :remainder
      assert_equal 2..-1, has_arg.arg_count
      has_arg << 'argument'
      assert !has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert has_arg.more_args?
      assert_equal 'argument', has_arg.required
      assert_equal %w{argument argument}, has_arg.remainder
    end

    should 'provide named arguments optionally taking all remainding arguments' do
      has_arg = HasArg.new :required, :remainder => [:optional, :remainder]
      assert_equal 1..-1, has_arg.arg_count
      has_arg << 'argument'
      assert has_arg.args_full?
      assert has_arg.more_args?
      has_arg << 'argument'
      assert has_arg.more_args?
      has_arg << 'argument'
      assert has_arg.more_args?
      assert_equal 'argument', has_arg.required
      assert_equal %w{argument argument}, has_arg.remainder
    end

    should 'call its code block if it is activated' do
      block_run = false
      has_arg = HasArg.new nil do
        block_run = true
      end
      has_arg.active!
      assert has_arg.active?
      assert block_run
    end

  end

end
