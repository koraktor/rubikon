# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'test_helper'

class ActionTests < Test::Unit::TestCase

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
