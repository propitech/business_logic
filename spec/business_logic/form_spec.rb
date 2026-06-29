# frozen_string_literal: true

require "spec_helper"
require "business_logic/form"

RSpec.describe BusinessLogic::Form do
  let(:form_class) do
    Class.new(described_class) do
      def self.name = "TestForm"

      def self.model_name = ActiveModel::Name.new(self, nil, "test_thing")

      attribute :first_name, :string
      attribute :age, :integer

      attr_accessor :tag_ids, :items_attributes
    end
  end

  describe ".from_params" do
    it "extracts the nested key matching model_name.param_key" do
      params = ActionController::Parameters.new(test_thing: {first_name: "Ada", age: "32"})
      form = form_class.from_params(params)
      expect(form).to have_attributes(first_name: "Ada", age: 32)
    end

    it "drops keys the form has no writer for", :aggregate_failures do
      params = ActionController::Parameters.new(test_thing: {first_name: "Ada", evil: "x"})
      form = form_class.from_params(params)
      expect(form.first_name).to eq("Ada")
      expect(form).not_to respond_to(:evil)
    end

    it "keeps array and nested values for keys with a writer", :aggregate_failures do
      params = ActionController::Parameters.new(
        test_thing: {tag_ids: %w[1 2], items_attributes: {"0" => {name: "x"}}}
      )
      form = form_class.from_params(params)
      expect(form.tag_ids).to eq(%w[1 2])
      expect(form.items_attributes).to eq("0" => {"name" => "x"})
    end

    it "returns a blank form when the key is missing" do
      form = form_class.from_params(ActionController::Parameters.new({}))
      expect(form.first_name).to be_nil
    end

    it "accepts a custom key" do
      params = ActionController::Parameters.new(other: {first_name: "Ada"})
      form = form_class.from_params(params, key: :other)
      expect(form.first_name).to eq("Ada")
    end
  end

  describe "mass assignment" do
    it "accepts ActionController::Parameters directly, without permitting", :aggregate_failures do
      params = ActionController::Parameters.new(first_name: "Ada")
      expect { form_class.new(params) }.not_to raise_error
      expect(form_class.new(params).first_name).to eq("Ada")
    end
  end

  describe "#assign_errors" do
    it "maps flat keys onto matching attributes" do
      form = form_class.new
      form.assign_errors(first_name: ["can't be blank"], age: ["must be positive"])
      expect(form.errors.to_hash).to eq(first_name: ["can't be blank"], age: ["must be positive"])
    end

    it "buckets unknown top-level keys under :base" do
      form = form_class.new
      form.assign_errors(mystery: ["nope"])
      expect(form.errors[:base]).to eq(["nope"])
    end

    it "flattens nested hashes and routes unknown paths to :base" do
      form = form_class.new
      form.assign_errors(address: {line1: ["blank"], country: ["bad"]})
      expect(form.errors[:base]).to contain_exactly("blank", "bad")
    end

    it "appends multiple messages for the same attribute" do
      form = form_class.new
      form.assign_errors(first_name: ["too short", "must be capitalized"])
      expect(form.errors[:first_name]).to eq(["too short", "must be capitalized"])
    end

    it "is chainable" do
      form = form_class.new
      expect(form.assign_errors({})).to be(form)
    end
  end

  describe "form binding" do
    it "exposes model_name for Rails form helpers" do
      expect(form_class.model_name.param_key).to eq("test_thing")
    end

    it "round-trips submitted attributes after a failed call" do
      form = form_class.new(first_name: "Ada")
      form.assign_errors(first_name: ["bad"])
      expect(form).to have_attributes(first_name: "Ada", errors: have_attributes(messages: {first_name: ["bad"]}))
    end
  end
end
