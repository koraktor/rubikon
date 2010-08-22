#!/usr/bin/env ruby
#
# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

if ENV['RUBIKON_DEV']
  require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'rubikon')
else
  require 'rubygems'
  require 'rubikon'
end

# A more complex Rubikon application
class ComplexSample < Rubikon::Application::Base

  # Greet the whole world per default
  flag :more
  default 'Simple hello world' do
    greet 'World'
    puts 'Nice to see you.' if given? :more
  end

  # Interactive mode
  #
  # Ask the user for his name and greet him
  command :interactive, 'Greet interactively' do
    name = input 'Please enter your name'
    greet name
  end

  # Show a progress bar while iterating through a loop
  command :progress, 'Display a progress bar' do
    put 'Watch my progress while I greet the world: '
    x = 1000000
    progress_bar(:char => '+', :maximum => x, :size => 30) do |progress|
      x.times do
        progress.+
      end
    end
  end

  # Sleep for 5 seconds while displaying a throbber
  command :throbber, 'Display a throbber' do
    put 'Greeting the whole world takes some time... '
    throbber do
      sleep 5
    end
    puts 'done.'
  end

  # A standard Ruby class method for greeting
  def greet(someone)
    puts "Hello #{someone}!"
  end

end
