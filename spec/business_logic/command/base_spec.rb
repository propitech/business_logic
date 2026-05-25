# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command::Base do
  include BusinessLogic::Matchers

  it "is the superclass of BusinessLogic::Command" do
    expect(BusinessLogic::Command.superclass).to eq(described_class)
  end

  describe "#execute" do
    it "is abstract on the base class" do
      expect { described_class.new.call }.to raise_error(NotImplementedError, /must implement #execute/)
    end
  end

  describe "single-shot" do
    let(:command_class) do
      Class.new(described_class) do
        def self.name = "Commands::Echo"

        param :value

        def execute = Success(value)
      end
    end

    it "returns the execute result on first call" do
      command = command_class.new("hi")
      expect(command.call).to succeed_command.with_value("hi")
    end

    it "raises AlreadyCalled on second invocation" do
      command = command_class.new("hi")
      command.call
      expect { command.call }.to raise_error(described_class::AlreadyCalled, /already called/)
    end
  end

  describe "option for input data" do
    let(:command_class) do
      Class.new(described_class) do
        option :user
        option :form

        def execute = Success("#{user}/#{form}")
      end
    end

    it "accepts keyword input via .call" do
      expect(command_class.call(user: "Ada", form: "F1"))
        .to succeed_command.with_value("Ada/F1")
    end
  end

  describe "no extensions wired" do
    # `respond_to?(:with)` is true on every Object once
    # ActiveSupport is loaded (`Object#with`), so we assert on the
    # extension-specific entry points instead.
    let(:subclass) { Class.new(described_class) { def execute = Success(:ok) } }

    it "does not expose .dependency without DependencyInjection" do
      expect(subclass).not_to respond_to(:dependency)
    end

    it "does not expose .bind_form without FormBinding" do
      expect(subclass).not_to respond_to(:bind_form)
    end
  end
end
