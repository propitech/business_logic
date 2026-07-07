# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::SeedUsesFactory, :config do
  it "flags a hand-rolled model create" do
    expect_offense(<<~RUBY)
      Space.create!(name: "Studio A")
            ^^^^^^^ #{format(described_class::MSG_CREATE, const: 'Space')}
    RUBY
  end

  it "flags a namespaced model create" do
    expect_offense(<<~RUBY)
      Billing::Invoice.create(amount: 10)
                       ^^^^^^ #{format(described_class::MSG_CREATE, const: 'Billing::Invoice')}
    RUBY
  end

  it "allows FactoryBot.create" do
    expect_no_offenses("FactoryBot.create(:space, :studio)")
  end

  it "allows FactoryGirl.create" do
    expect_no_offenses("FactoryGirl.create(:space)")
  end

  it "allows find_or_create_by" do
    expect_no_offenses('Country.find_or_create_by(code: "FR")')
  end

  it "allows create_with" do
    expect_no_offenses('Space.create_with(name: "A").find_or_create_by(slug: "a")')
  end

  it "allows create on a non-constant receiver (association)" do
    expect_no_offenses("space.bookings.create(starts_at: t)")
  end

  it "flags a command invocation" do
    expect_offense(<<~RUBY)
      Commands::Spaces::Create.call(name: "Studio A")
      ^^^^^^^^^^^^^^^^^^^^^^^^ #{format(described_class::MSG_COMMAND, const: 'Commands::Spaces::Create')}
    RUBY
  end

  it "reports a command reference once, not per namespace segment" do
    expect_offense(<<~RUBY)
      result = Commands::SavedSearches::Create.call(user: u)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(described_class::MSG_COMMAND, const: 'Commands::SavedSearches::Create')}
    RUBY
  end

  it "allows an unrelated constant" do
    expect_no_offenses("role = Membership::Roles::OWNER")
  end
end
