# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2010-2011, Sebastian Staudt

module Rubikon

  # This module is used to enhance an IO stream to generate terminal
  # color codes from simple text tags.
  #
  # @author Sebastian Staudt
  # @since 0.5.0
  module ColoredIO

    # Color codes that can be used inside a IO enhanced with ColoredIO
    COLORS = {
      :black  => 30,
      :bl     => 30,
      :red    => 31,
      :r      => 31,
      :green  => 32,
      :g      => 32,
      :yellow => 33,
      :y      => 33,
      :blue   => 34,
      :b      => 34,
      :purple => 35,
      :p      => 35,
      :cyan   => 37,
      :c      => 36,
      :white  => 37,
      :w      => 37,
    }

    # The keys of the color codes joined for the regular expression
    COLOR_MATCHER = COLORS.keys.join('|')

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
      return io if io.respond_to?(:color_filter)

      enabled = enabled && ENV['TERM'] != 'dumb'
      if enabled && RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/
        is_stdout = io == $stdout
        is_stderr = io == $stderr
        begin
          require 'Win32/Console/ANSI'
        rescue LoadError 
          enabled = false
        end
        io = $stdout if is_stdout
        io = $stderr if is_stderr
      end

      class << io
        const_set :COLORS, COLORS

        def puts(text = '')
          self.class.
            instance_method(:puts).bind(self).call color_filter(text.to_s)
        end
      end

      if enabled
        class << io
          def color_filter(text)
            text.gsub(/(#{COLOR_MATCHER})\{(.*?)\}/i) do
              "\e[0;#{COLORS[$1.downcase.to_sym]}m#{$2}\e[0m"
            end
          end
        end
      else
        class << io
          def color_filter(text)
            text.gsub(/(#{COLOR_MATCHER})\{(.*?)\}/i, '\2')
          end
        end
      end

      io
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
