#!/usr/bin/env ruby

require 'rubygems'
require 'rubikon'

# A simple Hello World application
class HelloWorld < Rubikon::Application

  # Don't add double-dashes to options automatically
  set :dashed_options, false

  # Greet the whole world per default
  default do
    greet "World"
  end

  # Interactive mode
  #
  # Ask the user for his name and greet him
  action '-i' do
    name = input 'Please enter your name'
    greet name
  end

  # Sleep for 5 seconds while displaying a throbber
  action '--throbber' do
    throbber do
      sleep 5
    end
  end

  # A standard Ruby class method for greeting
  def greet(someone)
    puts "Hello #{someone}!"
  end

end
