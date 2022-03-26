# frozen_string_literal: true

require 'pads/events/base'

module Pads
  module Events
    # Occurs when one of a pad's buttons are clicked.
    class ButtonClicked < Base
      # Zero-based index of the button that was clicked.
      # @return Integer
      attr_reader :index

      # Label of the button that was clicked.
      # @return String
      attr_reader :label

      def initialize(event_data)
        @index = event_data.fetch('index')
        @label = event_data.fetch('label')
        super()
      end
    end
  end
end
