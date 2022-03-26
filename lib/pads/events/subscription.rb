# frozen_string_literal: true

require 'set'

module Pads
  module Events
    # Represents an event subscription, and can be used to unsubscribe.
    class Subscription
      def initialize(publisher, proc)
        @publisher = publisher
        @proc      = proc
      end

      def unsubscribe
        @publisher.__send__ :unsubscribe, self
        self
      end

      private

      def call(*args, &block)
        @proc.call(*args, &block)
      end
    end
  end
end
