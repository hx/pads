# frozen_string_literal: true

require 'securerandom'

module Pads
  class TestClient
    def initialize
      @pads = []
    end

    def create_pad(before: nil, after: nil)
      raise 'You cannot specify before and after' if before && after

      index = if before
                @pads.index(resolve_pad(before))
              elsif after
                @pads.index(resolve_pad(after)) + 1
              else
                @pads.length
              end

      pad_id = SecureRandom.uuid
      Client::Pad.new(pad_id, self) { @pads.delete resolve_pad(pad_id) }.tap { |pad| @pads.insert index, pad }
    end

    def swap_pads(pad_or_range_a, pad_or_range_b) # rubocop:disable Metrics/AbcSize
      range_a = Array(pad_or_range_a)
      range_b = Array(pad_or_range_b)
      indexes_a = range_a.map(&@pads.method(:index))
      indexes_b = range_b.map(&@pads.method(:index))

      # This assumes range A occurs before range B

      slice_b = @pads.slice!(indexes_b.first..indexes_b.last)
      @pads.insert indexes_b.first, *@pads[indexes_a.first..indexes_a.last]
      @pads.slice! indexes_a.first..indexes_a.last
      @pads.insert indexes_a.first, *slice_b
    end

    def call(command, *args)
      # Nothing to do here
    end

    def pads
      @pads.dup
    end

    private

    def resolve_pad(pad_or_id)
      case pad_or_id
      when String
        @pads.find { |p| p.pad_id == pad_or_id } or
          raise "No pad with id #{pad_or_id}"
      when Client::Pad
        pad_or_id
      else
        raise ArgumentError
      end
    end
  end
end
