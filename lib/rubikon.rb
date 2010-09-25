# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'core_ext/string'
require 'rubikon/application/base'

module Rubikon

  VERSION = '0.2.1'

end
