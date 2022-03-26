# frozen_string_literal: true

module Pads
  class Provider
    # Represents a server binding for a pad group. Just an array, but uses object IDs for comparisons, so that e.g.
    # two empty groups are not considered equal.
    class GroupBinding < Array
      alias == equal?
    end
  end
end
