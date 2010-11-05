# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'yaml'

module Rubikon

  module Config

    # A configuration provider loading configuration data from YAML files
    #
    # @author Sebastian Staudt
    # @since 0.5.0
    class YamlProvider

      # Loads a configuration Hash from a YAML formatted file
      #
      # @param [String] file The path of the file to load
      # @return [Hash] The configuration data loaded from the file
      def load_config(file)
        YAML.load_file file
      end

    end

  end

end
