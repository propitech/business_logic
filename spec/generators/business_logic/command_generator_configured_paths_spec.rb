# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/command/command_generator"

RSpec.describe BusinessLogic::CommandGenerator do
  setup_default_destination

  context "with config.business_logic paths set" do
    around do |example|
      options = BusinessLogic::Railtie.config.business_logic
      previous = options.slice(:install_dir, :test_dir)
      options[:install_dir] = "lib/domain"
      options[:test_dir] = "test/domain"
      example.run
    ensure
      options.merge!(previous)
    end

    before { run_generator ["create_user"] }

    it "writes the class under install_dir" do
      expect(file("lib/domain/commands/create_user.rb")).to exist
    end

    it "writes the spec under test_dir" do
      expect(file("test/domain/commands/create_user_spec.rb")).to exist
    end
  end
end
