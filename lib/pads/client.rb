# frozen_string_literal: true

require 'interop'

require 'pads/client/pad'
require 'pads/client/local_resolver'

module Pads
  # Low-level client for Pads servers
  class Client
    def initialize(reader = nil, writer = nil)
      reader ||= LocalResolver.new.connect

      @pads = {}
      @rpc_client = Hx::Interop::RPC::Client.new(reader, writer || reader)
      @rpc_client.on(//) do |message|
        next unless (pad_id = message[:pad_id])

        @pads[pad_id]&.events&.dispatch(
          message[Hx::Interop::Headers::CLASS],
          message[Hx::Interop::Headers::CONTENT_TYPE] ? message.decode : message.body
        )
      end
    end

    def create_pad(before: nil, after: nil)
      raise 'You cannot specify before and after' if before && after

      headers = {
        before_pad_id: before && pad_id(before),
        after_pad_id:  after && pad_id(after)
      }.compact

      pad_id        = call(:create_pad, headers)[:pad_id]
      @pads[pad_id] = Pad.new(pad_id, self) { @pads.delete pad_id }
    end

    def swap_pads(pad_or_range_a, pad_or_range_b)
      call :swap_pads, Hx::Interop::ContentType::JSON.encode(
        range_a: pad_range(*Array(pad_or_range_a)),
        range_b: pad_range(*Array(pad_or_range_b))
      )
    end

    def wait
      @rpc_client.wait
    end

    def call(*args, &block)
      @rpc_client.call(*args, &block)
    end

    private

    def pad_id(pad_or_id)
      case pad_or_id
      when String
        pad_or_id
      when Pad
        @pads.key(pad_or_id) or
          raise 'The given pad does not belong to this client'
      else
        raise ArgumentError, "Unexpected #{pad_or_id.inspect}"
      end
    end

    def pad_range(first, last = first)
      {
        first_pad_id: pad_id(first),
        last_pad_id:  pad_id(last)
      }
    end
  end
end
