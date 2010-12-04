# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'helper'

class TestConfig < Test::Unit::TestCase

  context 'A configuration' do

    setup do
      path = File.join(File.dirname(__FILE__), 'config')
      @config_file = 'config.yml'
      @search_paths = []
      @search_paths << File.join(path, '0')
      @search_paths << File.join(path, '1')
      @search_paths << File.join(path, '2')
      @search_paths << File.join(path, '3')

      @factory = Rubikon::Config::Factory.new(@config_file, @search_paths)
    end

    should 'search multiple paths for a configuration file' do
      config_files = @search_paths[0..-2].map { |p| File.join(p, @config_file) }
      assert_equal config_files, @factory.files
    end

    should 'read the configuration from the specified files' do
      config = {
        :value     => 0,
        :value1    => 1,
        :value2    => 2,
        :overriden => 2
      }
      assert_equal config, @factory.config
    end

  end

end
