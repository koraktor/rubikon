# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

module Rubikon

  module Config

    # A configuration provider loading configuration data from INI files
    #
    # @author Sebastian Staudt
    # @since 0.5.0
    class IniProvider

      # Loads a configuration Hash from a INI file
      #
      # This method is taken from code written by gdsx in #ruby-lang (see
      # http://snippets.dzone.com/posts/show/563).
      #
      # @param [String] file The path of the file to load
      # @return [Hash] The configuration data loaded from the file
      def self.load_config(file)
        content = File.new(file).readlines.map do |line|
          line.gsub(/(?:#|;).*/, '').strip
        end.join("\n")

        config = {}
        content = content.split(/\[([^\]]+)\]/)[1..-1]
        content.inject([]) do |temp, field|
          temp << field
          if temp.length == 2
            value = temp[1].sub(/^\s+/,'').sub(/\s+$/,'')
            if config[temp[0]].nil?
              config[temp[0]] = value
            else
              config[temp[0]] << "\n#{value}"
            end
            temp.clear
          end
          temp
        end

        config.dup.each do |key, value|
          value_list = value.split /[\r\n]+/
          config[key] = value_list.inject({}) do |hash, val|
            k, v = val.split /\s*=\s*/
            hash[k] = v
            hash
          end
        end

        config
      end

      # Saves a configuration Hash into a INI file
      #
      # @param [Hash] config The configuration to write
      # @param [String] file The path of the file to write
      # @since 0.6.0
      def self.save_config(config, file)
        unless config.is_a? Hash
          raise ArgumentError.new('Configuration has to be a Hash')
        end

        file = File.new file, 'w'

        config.each do |key, value|
          if value.is_a? Hash
            file << "\n" if file.pos > 0
            file << "[#{key.to_s}]\n"

            value.each do |k, v|
              file << "  #{k.to_s} = #{v.to_s unless v.nil?}\n"
            end
          else
            file << "#{key.to_s} = #{value.to_s unless value.nil?}\n"
          end
        end

        file.close
      end

    end

  end

end
