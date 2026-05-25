# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command::DependencyInjection do
  include BusinessLogic::Matchers

  let(:base) do
    Class.new(BusinessLogic::Command::Base) do
      extend BusinessLogic::Command::DependencyInjection
    end
  end

  describe ".with" do
    let(:command_class) do
      Class.new(base) do
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

    it "hides Proxy as a private constant on Command" do
      expect { BusinessLogic::Command::Proxy }.to raise_error(NameError, /private constant/)
    end

    it "raises UnknownDependency when overriding a non-dependency option" do
      klass = Class.new(base) do
        option     :user
        dependency :contract, default: -> { :default }

        def execute = Success(user)
      end

      expect { klass.with(user: "Ada") }
        .to raise_error(BusinessLogic::Command::UnknownDependency, /:user.*not in declared dependencies/m)
    end

    it "raises UnknownDependency for completely unknown keys" do
      klass = Class.new(base) do
        dependency :contract, default: -> { :default }

        def execute = Success(:ok)
      end

      expect { klass.with(mystery: 1) }.to raise_error(BusinessLogic::Command::UnknownDependency)
    end
  end

  describe ".dependency" do
    let(:base_class) do
      Class.new(base) do
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
end
