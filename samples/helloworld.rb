#!/usr/bin/env ruby
#
# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

if ENV['RUBIKON_DEV']
  require File.join(File.dirname(__FILE__), '..', 'lib', 'rubikon')
else
  require 'rubygems'
  require 'rubikon'
end

# A simple Hello World application
class HelloWorld < Rubikon::Application::Base

  # Greet the whole world per default
  default do
    greet "World"
  end

  # Interactive mode
  #
  # Ask the user for his name and greet him
  action 'interactive' do
    name = input 'Please enter your name'
    greet name
  end

  # Sleep for 5 seconds while displaying a throbber
  action 'throbber' do
    put 'Greeting the whole world takes some time... '
    throbber do
      sleep 5
    end
    puts 'done.'
  end

  action 'progress' do
    progress_bar(3) do |progress|
      progress += 1
      sleep 0.5
      progress += 1
      sleep 0.5
      progress += 1
    end
  end

  # A standard Ruby class method for greeting
  def greet(someone)
    puts "Hello #{someone}!"
  end

end
