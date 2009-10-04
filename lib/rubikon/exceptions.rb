module Rubikon

  class MissingArgumentError < ArgumentError
  end

  class OddArgumentError < ArgumentError
  end

  class UnknownArgumentError < ArgumentError

    def initialize(arg)
      super "Unknown argument: #{arg}"
    end

  end

end
