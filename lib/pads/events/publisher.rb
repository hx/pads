# frozen_string_literal: true

require 'set'
require 'pads/events/subscription'

module Pads
  module Events
    # Manages event subscribers and distributes events to them.
    class Publisher
      def initialize(payload_class = nil)
        @payload_class = payload_class
        @handlers      = Set.new.compare_by_identity
      end

      def subscribe(&block)
        Subscription.new(self, block).tap { |h| @handlers << h }
      end

      def unsubscribe_all
        @handlers.clear
        self
      end

      def publish(payload = nil)
        payload = @payload_class.new(payload) if @payload_class && !payload.is_a?(@payload_class)
        @handlers.each do |handler|
          handler.__send__ :call, payload
        end
        payload
      end

      private

      def unsubscribe(handler)
        @handlers.delete handler
      end
    end
  end
end
