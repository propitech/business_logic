# frozen_string_literal: true

require "spec_helper"

RSpec.describe BusinessLogic::AbstractMethodError do
  it "is a NoMethodError, hence a StandardError a bare rescue catches", :aggregate_failures do
    expect(described_class.new).to be_a(NoMethodError)
    expect(described_class.new).to be_a(StandardError)
  end

  it "is not a ScriptError like NotImplementedError" do
    expect(described_class.ancestors).not_to include(ScriptError)
  end

  it "carries a message like any exception" do
    expect(described_class.new("subclass me").message).to eq("subclass me")
  end
end
