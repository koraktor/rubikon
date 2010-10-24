require 'rbconfig'

module Rubikon
  
  module ColoredIO

    # Enables color filtering on the given output stream (or another object
    # responding to +puts+)
    #
    # This wraps the IO's +puts+ method into a call to +color_filter+. The
    # +color_filter+ method is added dynamically to the singleton class of the
    # object and does either turn color tags given to the output stream into
    # their corresponding color code or it simply removes the color tags, if
    # coloring is disabled.
    #
    # @param [IO] io The IO object to add color filtering to
    # @raise TypeError if the given object does not respond to +puts+
    # @see .remove_color_filter
    def self.add_color_filter(io, enabled = true)
      raise TypeError unless io.respond_to? :puts
      return if io.respond_to?(:color_filter)

      enabled = enabled && ENV['TERM'] != 'dumb'
      if enabled && RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
        begin
          require 'Win32/Console/ANSI'
        rescue LoadError 
          enabled = false
        end
      end

      class << io
        COLORS = {
          :bl => 30,
          :r  => 31,
          :g  => 32,
          :y  => 33,
          :b  => 34,
          :p  => 35,
          :c  => 36,
          :w  => 37,
        }

        def puts(text = '')
          super color_filter(text.to_s)
        end
      end

      if enabled
        class << io
          def color_filter(text)
            text.gsub(/([bcgprwy]|bl)\{(.*?)\}/) do
              "\e[0;#{COLORS[$1.to_sym]}m#{$2}\e[0m"
            end
          end
        end
      else
        class << io
          def color_filter(text)
            text.gsub(/([bcgprwy]|bl)\{(.*?)\}/, '\2')
          end
        end
      end
    end

    # Disables color filtering on the given output stream
    #
    # This reverts the actions of +add_color_filter+
    #
    # @param [IO] io The IO object to remove color filtering from
    # @see .add_color_filter
    def self.remove_color_filter(io)
      return unless io.respond_to?(:color_filter)
      class << io
        remove_const  :COLORS
        remove_method :color_filter
        remove_method :puts
      end
    end

  end

end
