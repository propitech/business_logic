# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/contract/contract_generator"

RSpec.describe BusinessLogic::ContractGenerator do
  setup_default_destination

  before { run_generator ["create_user"] }

  describe "operation file" do
    subject { file("app/business_logic/contracts/create_user.rb") }

    # is_expected_to contain - verifies the file's contents
    it { is_expected.to contain(/class Contracts::CreateUser < ApplicationContract/) }
  end

  describe "spec file" do
    subject { file("spec/business_logic/contracts/create_user_spec.rb") }

    # is_expected_to contain - verifies the file's contents
    it { is_expected.to contain(/describe Contracts::CreateUser/) }
  end
end
