# frozen_string_literal: true

require 'pads/events/publisher'
require 'pads/events/button_clicked'
require 'pads/events/files_dropped'

module Pads
  module Events
    # A central object for dispatch all events related to an event subject.
    class Dispatcher
      DEFAULT_PUBLISHERS = {
        pad_clicked:    nil,
        button_clicked: Events::ButtonClicked,
        files_dropped:  Events::FilesDropped
      }.freeze

      attr_reader :publishers

      def initialize(publishers = DEFAULT_PUBLISHERS)
        @publishers = publishers.to_h do |event_name, event_class|
          [event_name.to_s, Publisher.new(event_class)]
        end.freeze
      end

      def on(event_name, &handler)
        @publishers.fetch(event_name.to_s).subscribe(&handler)
      end

      def dispatch(event_name, payload = nil)
        @publishers[event_name.to_s]&.publish payload
      end
    end
  end
end
