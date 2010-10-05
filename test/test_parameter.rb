# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'test_helper'
require 'testapps'

module TestParameter

  def setup
    @app = DummyApp.instance
    sandbox = nil
    @app.instance_eval do
      @path = File.dirname(__FILE__)
      sandbox = @sandbox
    end
    @sandbox = sandbox
  end

end
