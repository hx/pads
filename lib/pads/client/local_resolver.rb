# frozen_string_literal: true

require 'pathname'
require 'socket'
require 'json'

module Pads
  class Client
    # Creates raw connections based on the macOS app's configuration.
    class LocalResolver
      APP_CONTAINER_SUFFIX = 'Library/Containers/hx.pads/Data'
      LISTENERS_PATH       = '.pads/listeners.json'

      def initialize(home: Dir.home)
        @home = Pathname(home)
      end

      def connect
        errors = []
        each_config do |type, config|
          conn, error = __send__(:"try_#{type}", config)
          return conn if conn

          errors << error
        end
        raise errors.compact.first || 'Unable to connect to local server'
      end

      private

      def each_config
        %w[unix tcp].each do |type|
          parsed_listeners.each do |listeners|
            listeners[type]&.each do |config|
              yield type, config
            end
          end
        end
      end

      # @return [Array<Hash>]
      def parsed_listeners
        listeners_path_candidates
          .map do |path|
            next unless path.exist?

            JSON.parse path.readlines.delete_if { |l| l.start_with? '//' }.join
          end
          .compact
      end

      # @return [Array<Pathname>]
      def listeners_path_candidates
        [
          @home + LISTENERS_PATH,                        # Regular app version
          @home + APP_CONTAINER_SUFFIX + LISTENERS_PATH  # Sandboxed (app store) app version
        ]
      end

      def try_unix(config)
        try { UNIXSocket.new Pathname(config.fetch('path')).to_s }
      end

      def try_tcp(config)
        try { TCPSocket.new config.fetch('host', '127.0.0.1'), config.fetch('port') }
      end

      def try
        [yield, nil]
      rescue StandardError => e
        [nil, e]
      end
    end
  end
end
