# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::PreferSucceedValidation, :config do
  it "flags `not_to fail_validation`" do
    expect_offense(<<~RUBY)
      expect(result).not_to fail_validation
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert success with `succeed_validation.with_value(...)` instead of `not_to fail_validation`.
    RUBY
  end

  it "flags `not_to fail_contract`" do
    expect_offense(<<~RUBY)
      expect(result).not_to fail_contract
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert success with `succeed_contract.with_value(...)` instead of `not_to fail_contract`.
    RUBY
  end

  it "flags `not_to fail_operation`" do
    expect_offense(<<~RUBY)
      expect(result).not_to fail_operation
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert success with `succeed_operation.with_value(...)` instead of `not_to fail_operation`.
    RUBY
  end

  it "flags `not_to fail_command`" do
    expect_offense(<<~RUBY)
      expect(result).not_to fail_command
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert success with `succeed_command.with_value(...)` instead of `not_to fail_command`.
    RUBY
  end

  it "accepts the positive `succeed_*` assertion" do
    expect_no_offenses(<<~RUBY)
      expect(result).to succeed_validation.with_value(user: { name: "Ada" })
    RUBY
  end

  it "ignores unrelated negated matchers" do
    expect_no_offenses(<<~RUBY)
      expect(result).not_to be_failure
    RUBY
  end
end
