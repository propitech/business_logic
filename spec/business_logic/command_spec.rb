# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command do
  include BusinessLogic::Matchers

  describe "inheritance" do
    it "inherits from Command::Base" do
      expect(described_class.superclass).to eq(BusinessLogic::Command::Base)
    end
  end

  describe "extensions wired by default" do
    let(:subclass) { Class.new(described_class) { def execute = Success(:ok) } }

    it "exposes .dependency from DependencyInjection" do
      expect(subclass).to respond_to(:dependency)
    end

    it "exposes .bind_form from FormBinding" do
      expect(subclass).to respond_to(:bind_form)
    end
  end

  describe ".call" do
    let(:command_class) do
      Class.new(described_class) do
        param  :user
        option :greeting, default: -> { "hello" }

        def execute = Success("#{greeting}, #{user}")
      end
    end

    it "is sugar for new(...).call" do
      expect(command_class.call("Ada")).to succeed_command.with_value("hello, Ada")
    end

    it "accepts keyword options" do
      expect(command_class.call("Ada", greeting: "hi")).to succeed_command.with_value("hi, Ada")
    end
  end

  describe "Do notation (yield)" do
    let(:failing_class) do
      Class.new(described_class) do
        def execute
          value = yield Failure(:nope)
          Success(value)
        end
      end
    end

    it "short-circuits on Failure" do
      expect(failing_class.new.call).to fail_command
    end
  end

  describe "interop with Dry::Operation" do
    let(:command_class) do
      Class.new(described_class) do
        param :value
        def execute = Success(value * 2)
      end
    end
    let(:operation_class) do
      cmd = command_class
      Class.new(Dry::Operation) do
        define_method(:call) do |value|
          doubled = step cmd.new(value).call
          doubled + 1
        end
      end
    end

    it "operation can step on a command result" do
      expect(operation_class.new.call(3).value!).to eq(7)
    end
  end

  describe "#yield_model" do
    let(:record_class) do
      Class.new do
        def initialize(saved) = (@saved = saved)
        def save = @saved
        def errors = self
        def to_hash = {field: ["is invalid"]}
      end
    end
    let(:command_class) do
      Class.new(described_class) do
        param :record
        def execute
          saved = yield_model(record) { save }
          Success(saved)
        end
      end
    end

    it "continues with the record on a truthy write" do
      record = record_class.new(true)
      expect(command_class.call(record)).to succeed_command.with_value(record)
    end

    it "short-circuits with Failure on a falsy write — no explicit yield" do
      expect(command_class.call(record_class.new(false))).to fail_command
    end

    it "runs the write block in the record's context" do
      record = record_class.new(true)
      expect { command_class.call(record) }.not_to raise_error
    end
  end

  describe "#with_model" do
    let(:record_class) do
      Class.new do
        def initialize(saved) = (@saved = saved)
        def save = @saved
        def errors = self
        def to_hash = {field: ["is invalid"]}
      end
    end
    let(:command_class) do
      Class.new(described_class) do
        param :record
        def execute = with_model(record) { save }
      end
    end

    it "returns Success(record) on a truthy write — no re-wrap" do
      record = record_class.new(true)
      expect(command_class.call(record)).to succeed_command.with_value(record)
    end

    it "returns Failure(errors) on a falsy write without short-circuiting" do
      expect(command_class.call(record_class.new(false))).to fail_command
    end
  end

  describe "#yield_result" do
    include Dry::Monads[:result]

    let(:command_class) do
      Class.new(described_class) do
        param :inner
        def execute = Success(yield_result(inner))
      end
    end

    it "returns the value on Success" do
      expect(command_class.call(Success(:ok))).to succeed_command.with_value(:ok)
    end

    it "short-circuits on Failure — no explicit yield" do
      expect(command_class.call(Failure(:nope))).to fail_command
    end
  end
end
