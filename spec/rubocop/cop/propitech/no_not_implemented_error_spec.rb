# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::NoNotImplementedError, :config do
  it "flags and autocorrects a bare `raise NotImplementedError`" do
    expect_offense(<<~RUBY)
      raise NotImplementedError
            ^^^^^^^^^^^^^^^^^^^ Raise `BusinessLogic::AbstractMethodError` (a rescuable `NoMethodError`), not `NotImplementedError` (a `ScriptError`).
    RUBY

    expect_correction(<<~RUBY)
      raise BusinessLogic::AbstractMethodError
    RUBY
  end

  it "keeps the message when autocorrecting `raise NotImplementedError, msg`" do
    expect_offense(<<~RUBY)
      raise NotImplementedError, "subclass me"
            ^^^^^^^^^^^^^^^^^^^ Raise `BusinessLogic::AbstractMethodError` (a rescuable `NoMethodError`), not `NotImplementedError` (a `ScriptError`).
    RUBY

    expect_correction(<<~RUBY)
      raise BusinessLogic::AbstractMethodError, "subclass me"
    RUBY
  end

  it "flags the `.new` form" do
    expect_offense(<<~RUBY)
      raise NotImplementedError.new("nope")
            ^^^^^^^^^^^^^^^^^^^ Raise `BusinessLogic::AbstractMethodError` (a rescuable `NoMethodError`), not `NotImplementedError` (a `ScriptError`).
    RUBY

    expect_correction(<<~RUBY)
      raise BusinessLogic::AbstractMethodError.new("nope")
    RUBY
  end

  it "flags `fail NotImplementedError`" do
    expect_offense(<<~RUBY)
      fail NotImplementedError
           ^^^^^^^^^^^^^^^^^^^ Raise `BusinessLogic::AbstractMethodError` (a rescuable `NoMethodError`), not `NotImplementedError` (a `ScriptError`).
    RUBY

    expect_correction(<<~RUBY)
      fail BusinessLogic::AbstractMethodError
    RUBY
  end

  it "flags the top-level `::NotImplementedError`" do
    expect_offense(<<~RUBY)
      raise ::NotImplementedError
            ^^^^^^^^^^^^^^^^^^^^^ Raise `BusinessLogic::AbstractMethodError` (a rescuable `NoMethodError`), not `NotImplementedError` (a `ScriptError`).
    RUBY

    expect_correction(<<~RUBY)
      raise BusinessLogic::AbstractMethodError
    RUBY
  end

  it "ignores an unrelated raise" do
    expect_no_offenses(<<~RUBY)
      raise ArgumentError, "nope"
    RUBY
  end

  it "ignores raising the replacement itself" do
    expect_no_offenses(<<~RUBY)
      raise BusinessLogic::AbstractMethodError, "subclass me"
    RUBY
  end
end
