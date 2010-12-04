# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'helper'

class TestIniProvider < Test::Unit::TestCase

  context 'A configuration provider for INI files' do

    should 'return correct values' do
      ini = File.join(File.dirname(__FILE__), 'config', 'test.ini')
      expected = {
        'section' => {
          'value' => '1',
          'test1' => '1',
          'test2' => '2'
        }
      }
      assert_equal expected, Rubikon::Config::IniProvider.load_config(ini)
    end

  end

end
