# frozen_string_literal: true

module Generators
  module Macros
    # Tell the generator where to put its output (what it thinks of as
    # Rails.root)
    def set_default_destination
      destination File.expand_path("../../tmp/generators-test-tmp", __dir__)
    end

    def setup_default_destination
      set_default_destination
      before { prepare_destination }
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{spec/generators/}) do |metadata|
    metadata[:type] = :generator
  end

  config.extend Generators::Macros, type: :generator
end
