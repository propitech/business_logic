# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::PreferBeDeleted, :config do
  it "flags and rewrites `to be_present` as `to be_deleted`" do
    expect_offense(<<~RUBY)
      expect(record.deleted_at).to be_present
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(record).to be_deleted
    RUBY
  end

  it "flags and rewrites `not_to be_nil` as `to be_deleted`" do
    expect_offense(<<~RUBY)
      expect(address.reload.deleted_at).not_to be_nil
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(address.reload).to be_deleted
    RUBY
  end

  it "flags and rewrites `to be_nil` as `not_to be_deleted`" do
    expect_offense(<<~RUBY)
      expect(course.reload.deleted_at).to be_nil
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(course.reload).not_to be_deleted
    RUBY
  end

  it "flags and rewrites `not_to be_present` as `not_to be_deleted`" do
    expect_offense(<<~RUBY)
      expect(record.deleted_at).not_to be_present
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(record).not_to be_deleted
    RUBY
  end

  it "preserves a compound receiver expression" do
    expect_offense(<<~RUBY)
      expect(PhoneNumber.with_deleted.find(id).deleted_at).not_to be_nil
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(PhoneNumber.with_deleted.find(id)).to be_deleted
    RUBY
  end

  it "normalizes `to_not` to `not_to`" do
    expect_offense(<<~RUBY)
      expect(record.deleted_at).to_not be_nil
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Assert soft-delete with `be_deleted`, not the `deleted_at` column.
    RUBY

    expect_correction(<<~RUBY)
      expect(record).to be_deleted
    RUBY
  end

  it "accepts the `be_deleted` matcher" do
    expect_no_offenses(<<~RUBY)
      expect(record).to be_deleted
    RUBY
  end

  it "ignores a specific-timestamp assertion on `deleted_at`" do
    expect_no_offenses(<<~RUBY)
      expect(record.deleted_at).to eq(deletion_time)
    RUBY
  end

  it "ignores `deleted_at` matchers on a non-receiver call" do
    expect_no_offenses(<<~RUBY)
      expect(deleted_at).to be_present
    RUBY
  end
end
