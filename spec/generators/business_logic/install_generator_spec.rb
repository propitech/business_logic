# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/install/install_generator"

RSpec.describe BusinessLogic::InstallGenerator do
  setup_default_destination

  before do
    File.write(File.join(destination_root, "Gemfile"), "source \"https://rubygems.org\"\n")
    run_generator
  end

  describe "the base classes" do
    it "installs the command, contract and form base classes and the generators helper", :aggregate_failures do
      expect(file("app/business_logic/application_command.rb"))
        .to contain(/class ApplicationCommand < BusinessLogic::Command/)
      expect(file("app/business_logic/application_contract.rb"))
        .to contain(/class ApplicationContract < Dry::Validation::Contract/)
      expect(file("app/business_logic/application_form.rb"))
        .to contain(/class ApplicationForm < BusinessLogic::Form/)
      expect(file("spec/business_logic/generators_helper.rb")).to exist
    end

    it "does not install an operation base class" do
      expect(file("app/business_logic/application_operation.rb")).not_to exist
    end
  end

  describe "the Gemfile" do
    subject(:gemfile) { file("Gemfile") }

    it "adds the gems the base classes need", :aggregate_failures do
      expect(gemfile).to contain(/gem "ammeter", "~> 1.1", group: :test/)
      expect(gemfile).to contain(/gem "dry-initializer", "~> 3.1"/)
      expect(gemfile).to contain(/gem "dry-validation", "~> 1.10"/)
    end

    it "does not add dry-operation" do
      expect(gemfile).not_to contain(/dry-operation/)
    end
  end
end
