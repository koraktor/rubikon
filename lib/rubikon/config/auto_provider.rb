# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

module Rubikon

  module Config

    # A configuration provider loading various configuration file formats using
    # another provider depending on the extension of the configuration file.
    #
    # @author Sebastian Staudt
    # @since 0.5.0
    class AutoProvider

      # Load a configuration file with the corresponding provider detected
      # from the file extension
      #
      # @param [String] file The path of the config file to load
      # @return [Hash] The configuration values loaded from the file
      # @see IniProvider
      # @see YamlProvider
      def self.load_config(file)
        provider_for(file).load_config(file)
      end

      # Saves a configuration Hash with the corresponding provider detected
      # from the file extension
      #
      # @param [Hash] config The configuration to write
      # @param [String] file The path of the file to write
      # @see IniProvider
      # @see YamlProvider
      # @since 0.6.0
      def self.save_config(config, file)
        provider_for(file).save_config(config, file)
      end

      private

      # Returns the correct provider for the given file
      #
      # The file format is guessed from the file extension.
      #
      # @return Object A provider for the given file format
      # @since 0.6.0
      def provider_for(file)
        ext = File.extname(file)
        case ext
          when '.ini'
            IniProvider
          when '.yaml', '.yml'
            YamlProvider
          else
            raise UnsupportedConfigFormatError.new(ext)
        end
      end

    end

  end

end
