# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

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
      def self.load_config(file)
        YAML.load_file file
      end

      # Saves a configuration Hash into a YAML formatted file
      #
      # @param [Hash] config The configuration to write
      # @param [String] file The path of the file to write
      # @since 0.6.0
      def self.save_config(config, file)
        unless config.is_a? Hash
          raise ArgumentError.new('Configuration has to be a Hash')
        end

        file = File.new file, 'w'
        YAML.dump config, file
        file.close
      end

    end

  end

end
