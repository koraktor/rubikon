# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'core_ext/object'
require 'core_ext/string'
require 'rubikon/application/base'

# Rubikon is a simple to use, yet powerful Ruby framework for building
# console-based applications. Rubikon aims to provide an easy to write and easy
# to read domain-specific language (DSL) to speed up development of
# command-line applications. With Rubikon it's a breeze to implement
# applications with only few options as well as more complex programs like
# RubyGems, Homebrew or even Git.
#
# This is the namespace module for all Rubikon related code.
#
# @author Sebastian Staudt
# @since 0.1.0
module Rubikon

  # This is the current version of the Rubikon gem
  VERSION = '0.5.3'

end
