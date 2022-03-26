# frozen_string_literal: true

require 'pads/version'
require 'pads/provider'
require 'pads/mapper'
require 'pads/live_array'

# Provide pads to the Pads macOS app.
module Pads
  def self.provide(*args)
    provider = Provider.new(*args)
    yield provider
    provider.wait
  end

  def self.pad(*args, &block)
    Pad.new *args, &block
  end
end
