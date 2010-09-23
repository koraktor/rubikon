# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

require 'rake/testtask'

src_files = Dir.glob(File.join('lib', '**', '*.rb'))
test_files = Dir.glob(File.join('test', '**', '*.rb'))

task :default => :test

# Test task
Rake::TestTask.new do |t|
  t.libs << 'lib' << 'test'
  t.pattern = 'test/**/*_tests.rb'
  t.verbose = true
end

begin
  require 'jeweler'
  # Gem specification
  Jeweler::Tasks.new do |gem|
    gem.authors = ['Sebastian Staudt']
    gem.email = 'koraktor@gmail.com'
    gem.description = 'A simple to use, yet powerful Ruby framework for building console-based applications.'
    gem.date = Time.now
    gem.files = %w(README.md Rakefile LICENSE VERSION.yml) + src_files + test_files
    gem.has_rdoc = false
    gem.homepage = 'http://koraktor.github.com/rubikon'
    gem.name = gem.rubyforge_project = 'rubikon'
    gem.summary = 'Rubikon - A Ruby console app framework'

    gem.add_development_dependency('jewler')
    gem.add_development_dependency('yard')
  end
rescue LoadError
  puts 'You need Jeweler to build the gem. Install it using `gem install jeweler`.'
end

begin
  require 'yard'
  # Create a rake task +:doc+ to build the documentation using YARD
  desc 'Building docs'
  YARD::Rake::YardocTask.new do |yardoc|
    yardoc.name    = 'doc'
    yardoc.files   = ['lib/**/*.rb', 'LICENSE', 'README.md']
    yardoc.options = ['--private', '--title', 'Rubikon &mdash; API Documentation']
  end
rescue LoadError
  puts 'You need YARD to build the documentation. Install it using `gem install yard`.'
end

# Task for cleaning documentation and package directories
desc 'Clean documentation and package directories'
task :clean do
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'pkg'
end
