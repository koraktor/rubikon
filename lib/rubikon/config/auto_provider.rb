# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010, Sebastian Staudt

module Rubikon

  module Config

    class AutoProvider

      def load_config(file)
        ext = File.extname(file)
        case ext
          when 'yaml', 'yml'
            YamlProvider.load_config file
          else
            raise UnsupportedConfigFormatError.new(ext)
        end
      end

    end

  end

end
