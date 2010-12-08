# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rake/testtask'

samples_files = Dir.glob(File.join('samples', '**', '*.rb'))
src_files = Dir.glob(File.join('lib', '**', '*.rb'))
test_files = Dir.glob(File.join('test', '**', '*.rb'))

task :default => :test

# Test task
Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

begin
  gem 'ore-tasks', '~> 0.3.0'
  require 'ore/tasks'

  Ore::Tasks.new
rescue LoadError
  puts "Run `gem install ore-tasks` to install 'ore/tasks'."
end

begin
  require 'yard'

  # Create a rake task +:doc+ to build the documentation using YARD
  YARD::Rake::YardocTask.new do |yardoc|
    yardoc.name    = 'doc'
    yardoc.files   = ['lib/**/*.rb', 'LICENSE', 'README.md']
    yardoc.options = ['--private', '--title', 'Rubikon &mdash; API Documentation']
  end
rescue LoadError
  desc 'Generate YARD Documentation (not available)'
  task :doc do
    puts 'You need YARD to build the documentation. Install it using `gem install yard`.'
  end
end

# Task for cleaning documentation and package directories
desc 'Clean documentation and package directories'
task :clean do
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'pkg'
end
