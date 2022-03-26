# frozen_string_literal: true

require 'pads/pad_state'

module Pads
  # Mutable value object for pad state.
  class MutablePadState < PadState
    attr_writer :title, :subtitle, :activity, :clickable, :buttons, :is_drop_target

    def initialize(attrs = {})
      super()
      merge! DEFAULTS.merge(attrs)
    end

    def merge!(attrs)
      attrs.each do |key, value|
        __send__ :"#{key}=", value unless __send__(key) == value
      end
      self
    end
  end
end
