# frozen_string_literal: true

module Pads
  # Immutable value object for pad state.
  class PadState
    DEFAULTS = {
      title:          '',
      subtitle:       '',
      activity:       false,
      clickable:      false,
      buttons:        [],
      is_drop_target: false
    }.freeze

    attr_reader :title, :subtitle, :activity, :clickable, :buttons, :is_drop_target

    def initialize(attrs = {})
      DEFAULTS.merge(attrs).each do |key, value|
        raise ArgumentError, 'Unknown key' unless DEFAULTS.key?(key.to_sym)

        instance_variable_set :"@#{key}", value
      end
    end

    def to_h
      DEFAULTS.keys.to_h do |key|
        [key, instance_variable_get(:"@#{key}")]
      end
    end

    def merge(attrs)
      self.class.new to_h.merge(attrs)
    end

    def ==(other)
      return false unless other.is_a? PadState

      to_h == other.to_h
    end

    def self.[](obj)
      obj.is_a?(PadState) ? obj : PadState.new(obj)
    end
  end
end
