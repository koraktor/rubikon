# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/parameter'

module Rubikon

  # An option is an Application Parameter that may have one or more additional
  # arguments.
  class Option

    attr_reader :arg_count, :args

    include Parameter

  end

end
