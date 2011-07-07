require 'bundler'

require File.expand_path(File.dirname(__FILE__) + '/lib/rubikon/version')

Gem::Specification.new do |s|
  s.name        = 'rubikon'
  s.version     = Rubikon::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ 'Sebastian Staudt' ]
  s.email       = [ 'koraktor@gmail.com' ]
  s.homepage    = 'http://koraktor.de/rubikon'
  s.summary     = 'Rubikon - A Ruby console app framework'
  s.description = 'A simple to use, yet powerful Ruby framework for building console-based applications.'

  Bundler.definition.dependencies.each do |dep|
    if dep.groups.include?(:development) || dep.groups.include?(:test)
      s.add_development_dependency(dep.name, dep.requirement.to_s)
    else
      s.add_dependency(dep.name, dep.requirement.to_s)
    end
  end

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- test/*`.split("\n")
  s.require_paths      = [ 'lib' ]
end
