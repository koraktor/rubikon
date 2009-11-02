# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'test_helper'

class ProgressBarTests < Test::Unit::TestCase

  context 'A progress bar' do

    should 'have default settings' do
      @bar = Rubikon::ProgressBar.new
      assert_equal 0.2,     @bar.instance_variable_get(:@factor)
      assert_equal 100,     @bar.instance_variable_get(:@maximum)
      assert_equal $stdout, @bar.instance_variable_get(:@ostream)
      assert_equal 0,       @bar.instance_variable_get(:@progress)
      assert_equal '#',     @bar.instance_variable_get(:@progress_char)
      assert_equal 0,       @bar.instance_variable_get(:@value)
    end

    should 'be customizable' do
      options = {
        :char    => '+',
        :maximum => 10,
        :ostream => StringIO.new,
        :size    => 100,
        :start   => 5
      }
      @bar = Rubikon::ProgressBar.new(options)
      assert_equal options[:size].to_f / options[:maximum], @bar.instance_variable_get(:@factor)
      assert_equal options[:maximum], @bar.instance_variable_get(:@maximum)
      assert_equal options[:ostream], @bar.instance_variable_get(:@ostream)
      assert_equal options[:start].to_f / options[:maximum] * options[:size], @bar.instance_variable_get(:@progress)
      assert_equal options[:char], @bar.instance_variable_get(:@progress_char)
      assert_equal options[:start], @bar.instance_variable_get(:@value)
    end

    should 'draw correctly for different sizes' do
      ostream = StringIO.new
      options = { :ostream => ostream, :start => 50 }

      @bar = Rubikon::ProgressBar.new(options)
      assert_equal "#" * 10, ostream.string
      @bar + 50
      assert_equal "#" * 20, ostream.string

      ostream.string = ''
      options[:size] = 10

      @bar = Rubikon::ProgressBar.new(options)
      assert_equal "#" * 5, ostream.string
      @bar + 10
      assert_equal "#" * 6, ostream.string

      ostream.string = ''
      options[:size] = 100

      @bar = Rubikon::ProgressBar.new(options)
      assert_equal "#" * 50, ostream.string
      @bar + 30
      assert_equal "#" * 80, ostream.string
    end

    should 'not overflow' do
      ostream = StringIO.new
      options = { :ostream => ostream, :size => 100 }

      @bar = Rubikon::ProgressBar.new options
      @bar + 101
      assert_equal "#" * 100, ostream.string
      assert_equal 100, @bar.instance_variable_get(:@progress)
      assert_equal 101, @bar.instance_variable_get(:@value)

      ostream.string = ''
      options[:start] = 50

      @bar = Rubikon::ProgressBar.new options
      @bar + 51
      assert_equal "#" * 100, ostream.string
      assert_equal 100, @bar.instance_variable_get(:@progress)
      assert_equal 101, @bar.instance_variable_get(:@value)

      ostream.string = ''
      options[:start] = 101
      
      @bar = Rubikon::ProgressBar.new options
      assert_equal "#" * 100, ostream.string
      assert_equal 100, @bar.instance_variable_get(:@progress)
      assert_equal 101, @bar.instance_variable_get(:@value)
    end

  end

end
