# frozen_string_literal: true

module Pads
  # Common functionality for Pads and PadGroups
  module PadOrGroup
    include Observable

    def self.coerce(object)
      case object
      when Pad, PadGroup
        object
      when Hash
        Pad.new object
      when Array
        PadGroup.new object.map(&method(:coerce))
      when nil
        PadGroup.new
      else
        raise ArgumentError, "Cannot coerce #{object.inspect} to a pad or group of pads"
      end
    end

    alias == equal?

    attr_reader :parent

    def parent=(new_parent)
      return if parent == new_parent

      delete_observer parent if parent
      @parent = new_parent
      add_observer parent, :relay_notification if parent
    end
  end
end
