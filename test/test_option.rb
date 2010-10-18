# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'test_parameter'

class TestOption < Test::Unit::TestCase

  include TestParameter

  context 'A Rubikon option' do

    should 'be a Parameter with arguments' do
      assert Option.included_modules.include?(Parameter)
      assert Option.included_modules.include?(HasArguments)
    end

  end

end
