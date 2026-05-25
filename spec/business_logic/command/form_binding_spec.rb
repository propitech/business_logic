# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/form"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command::FormBinding do
  include BusinessLogic::Matchers

  let(:base) do
    Class.new(BusinessLogic::Command::Base) do
      extend BusinessLogic::Command::DependencyInjection
      extend BusinessLogic::Command::FormBinding
    end
  end

  let(:form_class) do
    Class.new(BusinessLogic::Form) do
      def self.name = "Forms::User"

      attribute :email, :string
      attribute :age, :integer
    end
  end

  let(:form) { form_class.new(email: "ada@example.com", age: 30) }

  describe "happy path" do
    let(:command_class) do
      Class.new(base) do
        dependency :form
        option     :user
        option     :user_attributes

        def execute = Success([user, user_attributes, form])
      end
    end

    it "injects form-sourced attributes and the form itself" do
      result = command_class
        .bind_form(form: form, user_attributes: :attributes)
        .call(user: "Ada")

      expect(result.value!).to eq(["Ada", {"email" => "ada@example.com", "age" => 30}, form])
    end

    it "leaves the form untouched on Success" do
      command_class.bind_form(form: form, user_attributes: :attributes).call(user: "Ada")
      expect(form.errors).to be_empty
    end
  end

  describe "Failure with Hash payload" do
    let(:command_class) do
      Class.new(base) do
        dependency :form
        option     :user_attributes

        def execute = Failure(email: ["is invalid"], age: ["must be >= 18"])
      end
    end

    it "assigns email errors onto the form as a side effect" do
      command_class.bind_form(form: form, user_attributes: :attributes).call
      expect(form.errors[:email]).to include("is invalid")
    end

    it "assigns age errors onto the form as a side effect" do
      command_class.bind_form(form: form, user_attributes: :attributes).call
      expect(form.errors[:age]).to include("must be >= 18")
    end

    it "returns the original Failure unchanged" do
      result = command_class.bind_form(form: form, user_attributes: :attributes).call
      expect(result.failure).to eq(email: ["is invalid"], age: ["must be >= 18"])
    end
  end

  describe "Failure with non-Hash payload" do
    let(:command_class) do
      Class.new(base) do
        dependency :form
        option     :user_attributes

        def execute = Failure(:not_found)
      end
    end

    it "leaves the form untouched" do
      command_class.bind_form(form: form, user_attributes: :attributes).call
      expect(form.errors).to be_empty
    end

    it "returns the original Failure unchanged" do
      result = command_class.bind_form(form: form, user_attributes: :attributes).call
      expect(result.failure).to eq(:not_found)
    end
  end

  describe "composition with .with" do
    let(:command_class) do
      Class.new(base) do
        dependency :form
        dependency :contract, default: -> { :default_contract }
        option     :user_attributes

        def execute = Success([contract, user_attributes, form])
      end
    end

    it ".with(...).bind_form(...) — overrides land alongside form injection" do
      result = command_class
        .with(contract: :override)
        .bind_form(form: form, user_attributes: :attributes)
        .call

      expect(result.value!).to eq([:override, {"email" => "ada@example.com", "age" => 30}, form])
    end

    it ".bind_form(...).with(...) — reverse order is equivalent" do
      result = command_class
        .bind_form(form: form, user_attributes: :attributes)
        .with(contract: :override)
        .call

      expect(result.value!).to eq([:override, {"email" => "ada@example.com", "age" => 30}, form])
    end

    it "validates .with overrides against the root command class in reverse order" do
      expect do
        command_class
          .bind_form(form: form, user_attributes: :attributes)
          .with(unknown_key: :value)
      end.to raise_error(BusinessLogic::Command::UnknownDependency)
    end
  end

  describe "lazy form lookup" do
    let(:command_class) do
      Class.new(base) do
        dependency :form
        option     :user_attributes

        def execute = Success(user_attributes)
      end
    end

    it "reads form attributes at .call time, not .bind_form time" do
      bound = command_class.bind_form(form: form, user_attributes: :attributes)
      form.email = "changed@example.com"
      result = bound.call
      expect(result.value!).to include("email" => "changed@example.com")
    end
  end

  describe "opt-in" do
    it "is not available on bare Command::Base subclasses" do
      bare = Class.new(BusinessLogic::Command::Base) { def execute = Success(:ok) }
      expect(bare).not_to respond_to(:bind_form)
    end
  end
end
