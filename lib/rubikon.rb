# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2009-2010, Sebastian Staudt

libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'core_ext/string'
require 'rubikon/application/base'

# A namespace module for all Rubikon related code
#
# @author Sebastian Staudt
# @since 0.1.0
module Rubikon

  VERSION = '0.2.1'

end
