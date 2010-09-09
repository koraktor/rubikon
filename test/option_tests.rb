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

    should 'allow the specified number of arguments' do
      option = Option.new :test, 2
      option << 'argument'
      assert_equal ['argument'], option.args
      option << 'argument'
      assert_equal ['argument', 'argument'], option.args
      assert_raise ExtraArgumentError do
        option << 'argument'
      end
      assert_equal ['argument', 'argument'], option.args
    end

  end

end
