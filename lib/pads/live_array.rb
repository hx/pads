# frozen_string_literal: true

require 'observer'

module Pads
  # An array that can be mapped to pads, and will update a pad group when it changes.
  class LiveArray < Array
    include Observable

    OBSERVED_METHODS = Set.new(
      %i[
        []= << push append prepend pop shift unshift insert
        delete delete_at delete_if keep_if fill clear replace
      ] + instance_methods.grep(/!$/)
    )

    OBSERVED_METHODS.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(*)              # def push(*)
          original = dup              #   original = dup
          result   = super            #   result   = super
          changed self != original    #   changed self != original
          notify_observers            #   notify_observers
          result                      #   result
        end                           # end
      RUBY
    end
  end
end
