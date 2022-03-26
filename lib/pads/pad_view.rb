# frozen_string_literal: true

require 'pads/observable_pad_state'

module Pads
  # Represents a stackable view of a pad
  class PadView < ObservablePadState
    attr_reader :events

    def self.[](obj)
      obj.is_a?(PadView) ? obj : new(obj)
    end

    def initialize(attrs = {})
      super

      @events = Events::Dispatcher.new
      @button_handlers = []

      @events.on :button_clicked do |event|
        @button_handlers[event.index]&.call
      end
    end

    def on_click(&handler)
      @events.on :pad_clicked, &handler
      self.clickable = true
    end

    def on_drop(path_pattern = nil, &handler)
      @events.on :files_dropped do |file_dropped|
        file_dropped.files.each do |file|
          handler.call(file.path) if path_pattern.nil? || file.path.match?(path_pattern)
        end
      end
      self.is_drop_target = true
    end

    def button(label, &handler)
      @button_handlers << handler
      self.buttons += [label]
    end
  end
end
