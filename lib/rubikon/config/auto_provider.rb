# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

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
      # @see YamlProvider
      def load_config(file)
        ext = File.extname(file)
        case ext
          when '.ini'
            IniProvider.new.load_config file
          when '.yaml', '.yml'
            YamlProvider.new.load_config file
          else
            raise UnsupportedConfigFormatError.new(ext)
        end
      end

    end

  end

end
