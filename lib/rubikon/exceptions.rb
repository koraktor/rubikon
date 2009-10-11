module Rubikon

  class MissingArgumentError < ArgumentError
  end

  class MissingOptionError < ArgumentError
  end

  class UnknownOptionError < ArgumentError

    def initialize(arg)
      super "Unknown argument: #{arg}"
    end

  end

end
