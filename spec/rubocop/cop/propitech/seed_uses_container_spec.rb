# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::SeedUsesContainer, :config do
  context "with a lookup verb" do
    it "flags `find_by` on a model constant" do
      expect_offense(<<~RUBY)
        School.find_by(slug: "movely-demo")
               ^^^^^^^ #{format(described_class::MSG_LOOKUP, method: 'find_by')}
      RUBY
    end

    it "flags `find` with an id (no block)" do
      expect_offense(<<~RUBY)
        School.find(1)
               ^^^^ #{format(described_class::MSG_LOOKUP, method: 'find')}
      RUBY
    end

    it "flags `find_by!` off an in-hand record" do
      expect_offense(<<~RUBY)
        school.memberships.find_by!(role: "admin")
                           ^^^^^^^^ #{format(described_class::MSG_LOOKUP, method: 'find_by!')}
      RUBY
    end
  end

  context "with a creation verb" do
    it "flags `find_or_create_by`" do
      expect_offense(<<~RUBY)
        Membership.find_or_create_by(role: "admin")
                   ^^^^^^^^^^^^^^^^^ #{format(described_class::MSG_CREATE, method: 'find_or_create_by')}
      RUBY
    end

    it "flags `find_or_initialize_by`" do
      expect_offense(<<~RUBY)
        Studio.find_or_initialize_by(name: "A")
               ^^^^^^^^^^^^^^^^^^^^^ #{format(described_class::MSG_CREATE, method: 'find_or_initialize_by')}
      RUBY
    end
  end

  context "with a mutation verb" do
    it "flags `update!` on an instance" do
      expect_offense(<<~RUBY)
        invoice.update!(due_at: t)
                ^^^^^^^ #{format(described_class::MSG_MUTATE, method: 'update!')}
      RUBY
    end

    it "flags `destroy_all` on a model constant" do
      expect_offense(<<~RUBY)
        Booking.destroy_all
                ^^^^^^^^^^^ #{format(described_class::MSG_MUTATE, method: 'destroy_all')}
      RUBY
    end

    it "flags `delete` on an instance" do
      expect_offense(<<~RUBY)
        row.delete
            ^^^^^^ #{format(described_class::MSG_MUTATE, method: 'delete')}
      RUBY
    end
  end

  context "when iterating" do
    it "allows `find_each`" do
      expect_no_offenses('School.where(status: "active").find_each { |school| school }')
    end

    it "allows the block form of `find`" do
      expect_no_offenses("roster.find { |member| member.active? }")
    end
  end

  it "leaves exact `create!` to the SeedUsesFactory cop" do
    expect_no_offenses('Space.create!(name: "A")')
  end

  it "allows FactoryBot builders" do
    expect_no_offenses("FactoryBot.create_list(:space, 2)")
  end

  it "allows an existence guard" do
    expect_no_offenses("Invoice.exists?(enrolment: enrolment)")
  end

  it "allows a scope without a terminal lookup" do
    expect_no_offenses('School.where(status: "active")')
  end

  it "does not mistake a scope or reader that merely contains a verb" do
    expect_no_offenses(<<~RUBY)
      School.with_deleted
      invoice.created_at
      membership.deleted?
    RUBY
  end

  it "allows a container fetch" do
    expect_no_offenses("school = container.get(:demo_school)")
  end
end
