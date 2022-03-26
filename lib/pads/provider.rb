# frozen_string_literal: true

require 'pads/client'
require 'pads/pad_group'
require 'pads/provider/tracking'

module Pads
  # The base class for a long-running process that provides pads to the Pads app.
  class Provider
    include Tracking

    def initialize(client = Client.new)
      @client = client
      @root   = PadGroup.new
      @mutex  = Mutex.new

      @bindings         = { @root => GroupBinding.new }.compare_by_identity
      @bindings_inverse = @bindings.invert.compare_by_identity

      @root.add_observer self, :pad_or_group_update
    end

    def push(*args, &block)
      @root.push(*args, &block)
    end

    def wait
      @client.wait
    end

    def pad_or_group_update(pad_or_group)
      return @mutex.synchronize { pad_or_group_update pad_or_group } unless @mutex.owned?

      if pad? pad_or_group
        pad_update pad_or_group
      else
        pad_group_update pad_or_group
      end
    end

    private

    # @param [Pads::Pad] pad
    def pad_update(pad)
      binding_for(pad).merge! pad.view.to_h
    end

    def pad_group_update(pad_group)
      pad_group_binding = binding_for(pad_group)
      remove_old_members pad_group, pad_group_binding
      sort_members pad_group, pad_group_binding
      add_new_members pad_group, pad_group_binding
    end

    def remove_old_members(pad_group, pad_group_binding)
      expected = Set.new(pad_group.members)
      pad_group_binding.each.with_index.reverse_each do |member_binding, index|
        member = pad_or_group_for(member_binding)
        next if expected.include? member

        destroy member
        pad_group_binding.delete_at index
      end
    end

    def sort_members(pad_group, pad_group_binding)
      return unless pad_group_binding.length > 1

      expected = pad_group.members.map(&@bindings.method(:[])) & pad_group_binding

      (0..(pad_group_binding.length - 2)).each do |i|
        a = expected[i]
        b = pad_group_binding[i]

        swap pad_group_binding, i, pad_group_binding.index(a) unless b == a
      end
    end

    def add_new_members(pad_group, pad_group_binding)
      create_options = self.create_options(binding_for(@root), pad_group_binding)

      pad_group.members.each.with_index do |member, index|
        binding = @bindings[member] ||
                  create_binding(member, create_options).tap { |b| pad_group_binding.insert index, b }

        create_options = { after: binding } if binding.is_a? Client::Pad
      end
    end

    def create_binding(member, create_options)
      is_pad = pad?(member)
      binding = is_pad ? @client.create_pad(**create_options) : GroupBinding.new

      @bindings[member]          = binding
      @bindings_inverse[binding] = member

      member.bind_events(binding.events) if is_pad

      pad_or_group_update(member)

      binding
    end

    def swap(pad_group_binding, index_a, index_b) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      bindings = [index_a, index_b].map(&pad_group_binding.method(:fetch))

      pad_group_binding[index_b], pad_group_binding[index_a] = bindings

      ranges = bindings.map(&method(:pad_range_for_binding)).sort_by { |range| range.nil? ? 1 : 0 }
      return if ranges.all?(&:nil?)

      ranges[1] ||= subtract_pad_range(pad_group_binding[index_a..index_b], ranges[0])
      return if ranges[1].nil?

      @client.swap_pads(*ranges)
    end

    def binding_for(pad_or_group)
      @bindings.fetch(pad_or_group) { raise "No server binding for #{pad_or_group}" }
    end

    def pad_or_group_for(binding)
      @bindings_inverse.fetch(binding)
    end

    def destroy(pad_or_group)
      binding = binding_for(pad_or_group)

      if pad? pad_or_group
        pad_or_group.unbind_events
        binding.destroy
      else
        binding.each(&method(:destroy))
      end

      @bindings.delete pad_or_group
      @bindings_inverse.delete binding
    end
  end
end
