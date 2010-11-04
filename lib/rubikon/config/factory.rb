# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

require 'rubikon/config/auto_provider'
require 'rubikon/config/yaml_provider'

module Rubikon

  module Config

    class Factory

      PROVIDERS = [ :auto, :yaml ]

      attr_reader :config, :files

      def initialize(name, search_paths, provider = :yaml)
        provider = :auto unless PROVIDERS.include?(provider)
        provider = Config.const_get("#{provider.to_s.capitalize}Provider").new
      
        @files  = []
        @config = {}
        search_paths.each do |path|
          config_file = File.join path, name
          if File.exists? config_file
            @config.merge! provider.load_config(config_file)
            @files << config_file
          end
        end
      end

    end

  end

end
