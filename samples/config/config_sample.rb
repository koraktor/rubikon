#!/usr/bin/env ruby
#
# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

if ENV['RUBIKON_DEV']
  require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'rubikon')
else
  require 'rubygems'
  require 'rubikon'
end

# A Rubikon application demonstrating the configuration feature
class ConfigSample < Rubikon::Application::Base

  dir = File.dirname __FILE__
  global_dir = File.join dir, 'global'
  local_dir = File.join dir, 'local'

  set :config_file, 'config.yml'
  set :config_paths, [ global_dir, local_dir ]

  global_flag :'exclude-local' do
    set :config_paths, [ global_dir ]

    puts "Seems like you changed the truth...\n\n"
  end

  default do
    puts "A pretty #{config[:string]} example of Rubikon's config."
    puts "#{config[:number]} is greater than 1."
    puts "A lie is never #{config[:boolean]}."
    puts 'Global configs are loaded...' if config[:global]
    puts 'and overriden by local configs' if config[:local]
  end

end
