# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2011, Sebastian Staudt

require 'rake/testtask'
require 'rubygems/package_task'

task :default => :test

# Test task
Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

# Rake tasks for building the gem
spec = Gem::Specification.load('rubikon.gemspec')
Gem::PackageTask.new(spec) do |pkg|
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
