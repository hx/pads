# frozen_string_literal: true

require 'pads/pad_group'
require 'pads/live_array'

module Pads
  # A Mapper binds an ObservableArray to a PadGroup
  class Mapper
    def self.map(source, id: :object_id, &mapper)
      if source.is_a? LiveArray
        new(source, id: id, &mapper).target
      else
        PadGroup.new Array(source).map(&mapper)
      end
    end

    # @return [PadGroup]
    attr_reader :target

    def initialize(source, id: :object_id, &mapper)
      raise ArgumentError, 'Expected a LiveArray' unless source.is_a? LiveArray

      @id     = id.to_proc
      @mapper = mapper
      @source = source
      @target = PadGroup.new
      @actual = []
      source.add_observer self
      update
    end

    def update
      ids = @source.map(&@id)
      @target.batch do
        remove_old_members ids
        sort_members ids
        add_new_members ids
      end
    end

    private

    def remove_old_members(ids)
      expected = Set.new(ids)
      @actual.each.with_index.reverse_each do |id, index|
        next if expected.include? id

        @actual.delete_at index
        @target.delete_at index
      end
    end

    def sort_members(ids)
      return unless @actual.length > 1

      expected = (ids & @actual)

      (0..(@actual.length - 2)).each do |i|
        next if expected[i] == @actual[i]

        j = @actual.index(expected[i])
        @actual[j], @actual[i] = @actual.values_at(i, j)
        @target.swap i, j
      end
    end

    def add_new_members(ids)
      skip = Set.new(@actual)
      @source.each.with_index do |object, index|
        id = ids[index]
        next if skip.include? id

        @actual.insert index, id
        @target.insert index, @mapper.call(object)
      end
    end
  end
end
