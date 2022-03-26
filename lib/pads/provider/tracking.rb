# frozen_string_literal: true

require 'pads/provider/group_binding'

module Pads
  class Provider
    # Supplemental methods for the Provider class
    module Tracking
      protected

      def pad?(pad_or_group)
        case pad_or_group
        when Pad, Client::Pad
          true
        when PadOrGroup, GroupBinding
          false
        else
          raise ArgumentError, 'Expected a pad or group'
        end
      end

      def pad_range_for_binding(binding)
        return [binding, binding] if pad? binding

        flat = binding.flatten
        flat.empty? ? nil : [flat.first, flat.last]
      end

      def subtract_pad_range(partial_group_binding, range_to_remove)
        indexes_to_remove = range_to_remove.map(&partial_group_binding.method(:index))
        remaining = partial_group_binding[
          indexes_to_remove.first.zero? ? (indexes_to_remove.last + 1).. : 0...indexes_to_remove.first
        ].flatten
        remaining.empty? ? nil : [remaining.first, remaining.last]
      end

      def walk(pad_group_binding, skip_group_bindings: true, &block)
        yield pad_group_binding unless skip_group_bindings

        pad_group_binding.each do |binding|
          if pad? binding
            block.call binding
          else
            walk binding, skip_group_bindings: skip_group_bindings, &block
          end
        end

        yield nil unless skip_group_bindings
      end

      def create_options(root_binding, pad_group_binding) # rubocop:disable Metrics/MethodLength
        create_options = {}
        phase          = 1 # 1 = before this group, 2 = in this group, 3 = after this group

        walk root_binding, skip_group_bindings: false do |binding|
          if binding == pad_group_binding
            break if create_options[:after]

            phase = 2
          elsif binding.nil?
            phase = 3
          elsif binding.is_a? GroupBinding
            next
          elsif phase == 1
            create_options[:after] = binding
          elsif phase == 3
            create_options[:before] = binding
            break
          end
        end

        create_options
      end
    end
  end
end
