# frozen_string_literal: true

require "spec_helper"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Matchers do
  include described_class

  it "has a success matcher" do
    expect(succeed_contract).to be_an_instance_of(BusinessLogic::Matchers::SuccessMatcher)
  end

  it "has a failure matcher" do
    expect(fail_contract).to be_an_instance_of(BusinessLogic::Matchers::FailureMatcher)
  end
end
