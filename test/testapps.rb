# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

class TestApp < Application::Base

  set :autorun, false
  set :name, 'Rubikon test application'
  set :raise_errors, true

  default do
    'default command'
  end

  command :input do
    input 'input'
  end

  command :alias_before => :object_id

  command :object_id do
    object_id
  end

  command :alias_after => :object_id

  flag :flag
  flag :f => :flag
  option :option, 1
  option :o => :option
  command :parameters do
    parameters
  end

  command :progressbar do
    progress_bar(:maximum => 4) do |progress|
      4.times { progress.+; puts 'test' }
    end
  end

  command :throbber do
    throbber do
      sleep 0.5
      puts 'don\'t'
      sleep 0.5
      puts 'break'
    end
  end

end

class TestAppWithoutDefault < Application::Base

  set :autorun, false
  set :help_as_default, false
  set :raise_errors, true

end
