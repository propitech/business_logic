# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::PreferFailValidation, :config do
  it "flags `not_to succeed_validation`" do
    expect_offense(<<~RUBY)
      expect(result).not_to succeed_validation
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert failure with `fail_validation.with_error(...)` instead of `not_to succeed_validation`.
    RUBY
  end

  it "flags `not_to succeed_contract`" do
    expect_offense(<<~RUBY)
      expect(result).not_to succeed_contract
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert failure with `fail_contract.with_error(...)` instead of `not_to succeed_contract`.
    RUBY
  end

  it "flags `not_to succeed_operation`" do
    expect_offense(<<~RUBY)
      expect(result).not_to succeed_operation
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert failure with `fail_operation.with_error(...)` instead of `not_to succeed_operation`.
    RUBY
  end

  it "flags `not_to succeed_command`" do
    expect_offense(<<~RUBY)
      expect(result).not_to succeed_command
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert failure with `fail_command.with_error(...)` instead of `not_to succeed_command`.
    RUBY
  end

  it "flags the `to_not` spelling" do
    expect_offense(<<~RUBY)
      expect(result).to_not succeed_command
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert failure with `fail_command.with_error(...)` instead of `not_to succeed_command`.
    RUBY
  end

  it "accepts the positive `fail_*` assertion" do
    expect_no_offenses(<<~RUBY)
      expect(result).to fail_validation.with_error(hash_including(:email))
    RUBY
  end

  it "ignores unrelated negated matchers" do
    expect_no_offenses(<<~RUBY)
      expect(result).not_to be_success
    RUBY
  end
end
