# frozen_string_literal: true

require 'pads'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each(&method(:require))
