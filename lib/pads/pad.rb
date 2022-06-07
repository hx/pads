# frozen_string_literal: true

require 'pads/pad_or_group'
require 'pads/pad_view'
require 'observer'

module Pads
  # Controls a single pad.
  class Pad
    include PadOrGroup

    attr_reader :events

    def initialize(attrs = {})
      @view_stack = []
      @events     = Events::Dispatcher.new

      push_view PadView.new(attrs)

      yield self if block_given?
    end

    def view
      @view_stack.first
    end

    def push_view(new_view = PadView.new)
      new_view = PadView[new_view]
      change_view { @view_stack.unshift new_view }
      yield new_view if block_given?
      new_view
    end

    def pop_view(view = self.view)
      index = @view_stack.index(view)

      raise ArgumentError, 'The given view is not part of the stack' if index.nil?
      raise ArgumentError, 'You cannot pop the top level view' if view == @view_stack.last

      change_view { @view_stack.slice! 0..index }
    end

    def with_view(new_view = PadView.new)
      new_view = PadView[new_view]
      push_view new_view
      yield new_view
    ensure
      pop_view new_view
    end

    def bind_events(source_dispatcher)
      @subscriptions = source_dispatcher.publishers.keys.map do |event_name|
        source_dispatcher.on(event_name) { |*args| view.events.dispatch event_name, *args }
      end.freeze
    end

    def unbind_events
      @subscriptions.each(&:unsubscribe)
      @subscriptions = nil
    end

    def view_changed(*)
      changed
      notify_observers self
    end

    private

    def method_missing(symbol, *args, &block)
      view = self.view
      if view.respond_to? symbol
        view.__send__ symbol, *args, &block
      else
        super
      end
    end

    def respond_to_missing?(symbol, *)
      view.respond_to?(symbol) or super
    end

    def change_view
      view&.delete_observer self
      yield
      view.add_observer self, :view_changed
      view_changed
      self
    end

    def compare
      old = view
      result = yield
      changed old != view
      notify_observers self
      result
    end
  end
end
