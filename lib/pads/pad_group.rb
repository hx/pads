# frozen_string_literal: true

require 'observer'
require 'pads/pad'
require 'pads/pad_or_group'

module Pads
  # Represents a group/sequence of pads.
  class PadGroup
    include PadOrGroup

    def initialize(members = [])
      @members = []
      @mutex   = Mutex.new

      batch { members.each(&method(:push)) }
    end

    def insert(index, pad_or_group)
      raise ArgumentError, 'Index out of range' unless (0..@members.length).cover? index

      pad_or_group        = PadOrGroup.coerce(pad_or_group)
      pad_or_group.parent = self
      batch { @members.insert index, pad_or_group }
    end

    def delete_at(index)
      batch do
        @members.delete_at(index).tap { |p| p.parent = nil } or
          raise ArgumentError, 'Nothing to delete at the given index'
      end
    end

    def swap(index_a, index_b)
      raise ArgumentError, 'Index out of range' unless [index_a, index_b].all?(&(0..@members.length).method(:cover?))
      raise ArgumentError, 'Indexes are identical' if index_a == index_b

      batch do
        @members[index_a], @members[index_b] = @members.values_at(index_b, index_a)
      end
    end

    def batch
      return yield if @mutex.owned?

      result = @mutex.synchronize do
        previous = @members.dup
        yield.tap do
          changed previous != @members
        end
      end
      notify_observers self
      result
    end

    def push(*args, &block)
      return push Mapper.map(*args, &block) if block

      batch do
        args.each do |arg|
          insert @members.length, arg
        end
      end
    end

    alias << push

    # @return [Array<Pad, PadGroup>]
    def members
      @members.dup
    end

    def relay_notification(*args)
      changed
      notify_observers(*args)
    end
  end
end
