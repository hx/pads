# frozen_string_literal: true

require 'pads/mutable_pad_state'
require 'observer'

module Pads
  # A mutable pad state that can be observed.
  class ObservablePadState < MutablePadState
    include Observable

    DEFAULTS.each_key do |key|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{key}=(*)        # def title=(*)
          compare { super }   #   compare { super }
        end                   # end
      RUBY
    end

    def merge!(*)
      compare { super }
    end

    private

    def compare
      return yield if @is_comparing

      @is_comparing = true
      begin
        old    = to_h
        result = yield
        changed to_h != old
      ensure
        @is_comparing = false
      end
      notify_observers self
      result
    end
  end
end
