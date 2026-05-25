# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/command/command_generator"

RSpec.describe BusinessLogic::CommandGenerator do
  setup_default_destination

  before { run_generator ["create_user"] }

  describe "command file" do
    subject { file("app/business_logic/commands/create_user.rb") }

    it { is_expected.to contain(/class Commands::CreateUser < ApplicationCommand/) }
  end

  describe "spec file" do
    subject { file("spec/business_logic/commands/create_user_spec.rb") }

    it { is_expected.to contain(/describe Commands::CreateUser/) }
  end
end
