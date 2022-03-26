# frozen_string_literal: true

require 'pads/events/dispatcher'
require 'pads/mutable_pad_state'

module Pads
  class Client
    # Proxy to a Client for a specific pad
    class Pad < MutablePadState
      attr_reader :events, :pad_id

      def initialize(pad_id, client, &on_destroy)
        @pad_id     = pad_id
        @client     = client
        @on_destroy = on_destroy
        @events     = Events::Dispatcher.new

        super()
      end

      def destroy
        call :destroy_pad
        @client = nil
        @on_destroy.call
        @on_destroy = nil
      end

      def title=(new_title)
        call :set_pad_title, new_title.to_s
        super
      end

      def subtitle=(new_subtitle)
        call :set_pad_subtitle, new_subtitle.to_s
        super
      end

      def activity=(fraction)
        call :set_pad_activity, transform_activity(fraction)
        super
      end

      def clickable=(clickable)
        call :set_pad_clickable, clickable ? true : false
        super
      end

      def buttons=(buttons)
        call :set_pad_buttons, buttons&.map { |i| { label: i.to_s } } || []
        super
      end

      def is_drop_target=(is_drop_target)
        call :set_pad_is_drop_target, is_drop_target ? true : false
        super
      end

      def on_pad_clicked(&handler)
        @events.on :pad_clicked, &handler
      end

      # @yieldparam [Pads::Events::ButtonClicked]
      def on_button_clicked(&handler)
        @events.on :button_clicked, &handler
      end

      # @yieldparam [Pads::Events::FilesDropped]
      def on_files_dropped(&handler)
        @events.on :files_dropped, &handler
      end

      alias == equal?

      private

      def call(class_name, arg = nil)
        raise 'Pad was destroyed' unless @client

        @client.call class_name, Hx::Interop::ContentType::JSON.encode(arg), pad_id: @pad_id
      end

      def transform_activity(fraction_or_bool)
        case fraction_or_bool
        when true, false, nil
          { busy: fraction_or_bool == true, progress: nil }
        when Numeric
          { busy: false, progress: fraction_or_bool.to_f.clamp(0, 1) }
        else
          raise ArgumentError, 'Expected nil, boolean, or a number'
        end
      end
    end
  end
end
