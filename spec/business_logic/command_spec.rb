# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command do
  include BusinessLogic::Matchers

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

  describe ".with" do
    let(:command_class) do
      Class.new(described_class) do
        param      :user
        dependency :greeting, default: -> { "hello" }

        def execute = Success("#{greeting}, #{user}")
      end
    end

    it "overrides dependencies at call time" do
      result = command_class.with(greeting: "ahoy").call("Ada")
      expect(result).to succeed_command.with_value("ahoy, Ada")
    end

    it "does not leak overrides across calls" do
      proxy = command_class.with(greeting: "ahoy")
      proxy.call("Ada")
      direct = command_class.new("Bo")
      expect(direct.call).to succeed_command.with_value("hello, Bo")
    end

    it "hides Proxy as a private constant" do
      expect { described_class::Proxy }.to raise_error(NameError, /private constant/)
    end

    it "raises UnknownDependency when overriding a non-dependency option" do
      klass = Class.new(described_class) do
        option     :user
        dependency :contract, default: -> { :default }

        def execute = Success(user)
      end

      expect { klass.with(user: "Ada") }
        .to raise_error(described_class::UnknownDependency, /:user.*not in declared dependencies/m)
    end

    it "raises UnknownDependency for completely unknown keys" do
      klass = Class.new(described_class) do
        dependency :contract, default: -> { :default }

        def execute = Success(:ok)
      end

      expect { klass.with(mystery: 1) }.to raise_error(described_class::UnknownDependency)
    end
  end

  describe ".dependency" do
    let(:base_class) do
      Class.new(described_class) do
        dependency :logger, default: -> { :base_logger }

        def execute = Success(logger)
      end
    end

    it "registers names in .dependencies" do
      expect(base_class.dependencies).to include(:logger)
    end

    context "with a subclass adding another dependency" do
      let(:child) do
        Class.new(base_class) do
          dependency :mailer, default: -> { :base_mailer }
        end
      end

      it "child sees both parent and own dependencies" do
        expect(child.dependencies).to include(:logger, :mailer)
      end

      it "parent does not gain child's dependencies" do
        child # trigger definition
        expect(base_class.dependencies).not_to include(:mailer)
      end
    end

    it "wires the option as overridable via .with" do
      result = base_class.with(logger: :override).call
      expect(result).to succeed_command.with_value(:override)
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
end
