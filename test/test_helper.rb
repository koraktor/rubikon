# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.dirname(__FILE__)
require 'rubikon'
include Rubikon

require 'rubygems'
require 'shoulda'

unless RUBY_VERSION[0..2] == '1.9'
  begin require 'redgreen'; rescue LoadError; end
end
