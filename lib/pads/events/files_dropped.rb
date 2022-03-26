# frozen_string_literal: true

require 'pads/events/base'

require 'pathname'
require 'uri'

module Pads
  module Events
    # Occurs when files are dropped on a pad.
    class FilesDropped < Base
      File = Struct.new(:path)

      # @return Array<File>
      attr_reader :files

      def initialize(event_data)
        @files = event_data.map do |file|
          File.new Pathname URI.decode_www_form_component URI(file.fetch('url')).path
        end
        super()
      end
    end
  end
end
