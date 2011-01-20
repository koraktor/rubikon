# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

require 'rubikon/config/auto_provider'
require 'rubikon/config/ini_provider'
require 'rubikon/config/yaml_provider'

module Rubikon

  # This module contains several classes used to load configuration data from
  # various sources
  #
  # @author Sebastian Staudt
  # @since 0.5.0
  module Config

    # The configuration factory is used to load one or more configuration
    # files from different search paths and using different file formats, e.g.
    # YAML.
    #
    # @author Sebastian Staudt
    class Factory

      # Providers available for use
      PROVIDERS = [ :auto, :ini, :yaml ]

      # @return [Hash] The configuration data loaded from the configuration
      #         files found inside the search paths
      attr_reader :config

      # @return [Array<String>] The paths of the configuration files found and
      #        loaded 
      attr_reader :files

      # Creates a new factory instance with a given file name to be searched in
      # the given paths and using the specified provider to load the
      # configuration data from the files.
      #
      # @param [String] name The name of the configuration file
      # @param [Array<String>] search_paths An array of paths to be searched
      #        for configuration files
      # @param [PROVIDERS] provider The provider to use for loading
      #        configuration data from the files found
      def initialize(name, search_paths, provider = :yaml)
        provider = :auto unless PROVIDERS.include?(provider)
        @provider = Config.const_get("#{provider.to_s.capitalize}Provider")
      
        @files  = []
        @config = {}
        search_paths.each do |path|
          config_file = File.join path, name
          if File.exists? config_file
            @config.merge! @provider.load_config(config_file)
            @files << config_file
          end
        end
      end

      # Save the given configuration into the specified file
      #
      # @param [Hash] The configuration to save
      # @param [String] The file path where the configuration should be saved
      # @since 0.6.0
      def save_config(config, file)
        unless config.is_a? Hash
          raise ArgumentError.new('Configuration has to be a Hash')
        end

        @provider.save_config config, file
      end

    end

  end

end
