# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/operation/operation_generator"

RSpec.describe BusinessLogic::OperationGenerator do
  setup_default_destination

  before { run_generator ["create_user"] }

  describe "operation file" do
    subject { file("app/business_logic/operations/create_user.rb") }

    # is_expected_to contain - verifies the file's contents
    it { is_expected.to contain(/class Operations::CreateUser < ApplicationOperation/) }
  end

  describe "spec file" do
    subject { file("spec/business_logic/operations/create_user_spec.rb") }

    # is_expected_to contain - verifies the file's contents
    it { is_expected.to contain(/describe Operations::CreateUser/) }
  end
end
