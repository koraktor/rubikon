# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

class DummyApp < Application::Base

  set :autorun, false

  attr_accessor :external_command_run

end

class TestApp < Application::Base

  set :autohelp, false
  set :autorun, false
  set :name, 'Rubikon test application'
  set :raise_errors, true

  attr_reader :commands, :global_parameters

  global_flag :gf1 => :gflag
  global_flag :gflag do
    @global = 'flag'
  end
  global_flag :gf2 => :gflag

  global_option :go1 => :gopt
  global_option :gopt, 1 do
    @global = args[0]
  end
  global_option :go2 => :gopt

  default nil, :hidden do
    'default command'
  end

  option :arg, [:opt_arg] do
    @result = []
    @result << opt_arg
  end
  command :arguments, [:cmd_arg] do
    @result << arg.opt_arg
    @result << cmd_arg
    @result
  end

  command :input do
    [input('input'), input('validated', 'x')]
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

  command :sandbox, 1 do
    send(args[0].to_sym)
  end

  command :globalopt do
    @global
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

  attr_reader :commands

end

class TestAppWithHooks < Application::Base

  set :autorun, false

  pre_init do
    puts 'pre init'
  end

  post_init do
    puts 'post init'
  end

  pre_execute do
    puts 'pre execute'
  end

  post_execute do
    puts 'post execute'
  end

  command :execute do
    puts 'execute'
  end

end
