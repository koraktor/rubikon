# This code is free software; you can redistribute it and/or modify it under the
# terms of the new BSD License.
#
# Copyright (c) 2009, Sebastian Staudt

require 'rake/rdoctask'
require 'rake/testtask'
require 'jeweler'

src_files = Dir.glob(File.join('lib', '**', '*.rb'))
test_files = Dir.glob(File.join('test', '**', '*.rb'))

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.test_files = test_files
  t.verbose = true
end

# Gem specification
Jeweler::Tasks.new do |s|
  s.authors = ['Sebastian Staudt']
  s.email = 'koraktor@gmail.com'
  s.description = 'A simple to use, yet powerful Ruby framework for building console-based applications.'
  s.date = Time.now
  s.homepage = 'http://koraktor.github.com/rubikon'
  s.name = s.rubyforge_project = 'rubikon'
  s.summary = 'Rubikon - A Ruby console app framework'

  s.files = %w(README.md Rakefile LICENSE VERSION.yml) + src_files + test_files
  s.rdoc_options = ['--all', '--inline-source', '--line-numbers', '--charset=utf-8', '--webcvs=http://github.com/koraktor/rubikon/blob/master/ruby/%s']
end

# Create a rake task +:rdoc+ to build the documentation
desc 'Building docs'
Rake::RDocTask.new do |rdoc|
  rdoc.title = 'Rubikon - API documentation'
  rdoc.rdoc_files.include ['lib/**/*.rb', 'test/**/*.rb', 'LICENSE', 'README.md']
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options = ['--all', '--inline-source', '--line-numbers', '--charset=utf-8', '--webcvs=http://github.com/koraktor/rubikon/blob/master/ruby/%s']
end

# Task for cleaning documentation and package directories
desc 'Clean documentation and package directories'
task :clean do
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'pkg'
end
