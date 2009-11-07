# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'test_helper'

class ThrobberTests < Test::Unit::TestCase

  context 'A throbber' do

    should 'be a subclass of Thread' do
      assert_equal Thread, Rubikon::Throbber.superclass
    end

    should 'have default throbber strings' do
      assert_equal %w{SPINNER}, Throbber.constants
      assert_equal '-\|/', Rubikon::Throbber.const_get(:SPINNER)
    end

  end

end
