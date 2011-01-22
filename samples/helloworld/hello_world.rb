#!/usr/bin/env ruby
#
# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

if ENV['RUBIKON_DEV']
  require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'rubikon')
else
  require 'rubygems'
  require 'rubikon'
end

# A relatively simple Hello World application using Rubikon
class HelloWorld < Rubikon::Application::Base

  # Greet the whole world per default
  flag :more, 'Display more information while greeting'
  option :name, 'A single name to greet', :who
  option :names, 'One or more names to greet', :who => :remainder
  option :special, 'A special name', :who => ['Guybrush', /LeChuck/, :numeric]
  default 'Simple hello world' do
    debug 'Starting to greet the world...'
    if given? :name
      names = [who]
    elsif given? :names
      names = who
    elsif given? :special
      names = [who]
    else
      names = %w{World}
    end

    names.each { |name| greet name }

    puts 'Nice to see you.' if given? :more
  end

  # Interactive mode
  #
  # Ask the user for his name and greet him
  command :interactive, 'Greet interactively' do
    name = input 'Please enter your name'
    call :__default, '--name', name
  end

  # Show a progress bar while iterating through a loop
  flag :brackets, 'Show brackets around the progress bar'
  command :progress, 'Display a progress bar' do
    put 'Watch my progress while I greet the world: '
    x = 1000000
    progress_bar(:char => '+', :maximum => x, :size => 30, :brackets => brackets.given?, :bracket_filler => '-') do |progress|
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
