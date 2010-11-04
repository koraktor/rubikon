# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'yaml'

module Rubikon

  module Config

    class YamlProvider

      def load_config(file)
        YAML.load_file file
      end

    end

  end

end
