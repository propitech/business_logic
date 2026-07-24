# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command::RescueFrom do
  include BusinessLogic::Matchers

  before { I18n.backend.store_translations(:en, rescue_from: {invalid: "is invalid"}) }

  let(:base) do
    Class.new(BusinessLogic::Command::Base) do
      extend BusinessLogic::Command::RescueFrom
    end
  end

  describe "with: a Symbol" do
    let(:command_class) do
      Class.new(base) do
        rescue_from ArgumentError, with: :invalid_selection

        def execute = raise(ArgumentError, "'nope' is not a valid status")
      end
    end

    it "returns the Symbol as the Failure payload" do
      expect(command_class.call).to fail_command.with_error(:invalid_selection)
    end
  end

  describe "with: a Hash" do
    let(:command_class) do
      Class.new(base) do
        rescue_from ArgumentError, with: {base: "rescue_from.invalid"}

        def execute = raise(ArgumentError)
      end
    end

    it "translates each value into a message array" do
      expect(command_class.call).to fail_command.with_error(base: ["is invalid"])
    end
  end

  describe "matching" do
    let(:command_class) do
      Class.new(base) do
        rescue_from IndexError, with: :handled

        def execute = raise(exception_class)

        def exception_class = KeyError
      end
    end

    it "matches a subclass of the registered exception" do
      expect(command_class.call).to fail_command.with_error(:handled)
    end

    it "lets an unregistered exception propagate unchanged" do
      unregistered = Class.new(command_class) { def exception_class = TypeError }
      expect { unregistered.call }.to raise_error(TypeError)
    end
  end

  describe "the registry" do
    let(:parent) do
      Class.new(base) do
        rescue_from ArgumentError, with: :from_parent

        def execute = raise(exception_class)
      end
    end

    let(:child) do
      Class.new(parent) do
        rescue_from TypeError, with: :from_child

        def exception_class = TypeError
      end
    end

    it "is frozen" do
      expect(parent.rescue_handlers).to be_frozen
    end

    it "starts empty on a class that declared nothing" do
      expect(base.rescue_handlers).to eq({})
    end

    it "inherits the parent's mappings" do
      inheriting = Class.new(child) { def exception_class = ArgumentError }
      expect(inheriting.call).to fail_command.with_error(:from_parent)
    end

    it "applies the subclass's own mappings" do
      expect(child.call).to fail_command.with_error(:from_child)
    end

    it "does not leak the subclass's mappings back to the parent" do
      leaking = Class.new(parent) { def exception_class = TypeError }
      expect { leaking.call }.to raise_error(TypeError)
    end
  end

  describe "ordering against the base #call" do
    it "leaves an auto-yielded Failure alone" do
      command_class = Class.new(base) do
        rescue_from StandardError, with: :handled

        def execute = Success(yield_result(Failure(:from_execute)))
      end
      expect(command_class.call).to fail_command.with_error(:from_execute)
    end

    it "never maps the single-shot guard to a Failure" do
      command_class = Class.new(base) do
        rescue_from StandardError, with: :handled

        def execute = Success(:ok)
      end
      command = command_class.new
      command.call
      expect { command.call }.to raise_error(BusinessLogic::Command::AlreadyCalled)
    end
  end

  describe "opt-in" do
    it "is pre-extended onto BusinessLogic::Command" do
      expect(BusinessLogic::Command).to respond_to(:rescue_from)
    end

    it "is not available on bare Command::Base subclasses" do
      bare = Class.new(BusinessLogic::Command::Base) { def execute = Success(:ok) }
      expect(bare).not_to respond_to(:rescue_from)
    end
  end
end
