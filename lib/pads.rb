# frozen_string_literal: true

require 'pads/version'
require 'pads/provider'
require 'pads/mapper'
require 'pads/live_array'

# Provide pads to the Pads macOS app.
module Pads
  def self.run(*args, &block)
    loop do
      run! *args, &block
    rescue Errno::ECONNREFUSED
      sleep 1
    end
  end

  def self.run!(*args)
    provider = Provider.new(*args)
    Thread.new { yield provider }
    provider.wait
  end

  def self.pad(*args, &block)
    Pad.new *args, &block
  end
end
