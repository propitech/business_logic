# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "rubocop/business_logic/plugin"

RSpec.describe RuboCop::Cop::Propitech::CommandActorPolicy, :config do
  let(:cop_config) do
    {"PolicyMacros" => ["option :actor", "runs_as_system", "runs_inside", "runs_signed_out"]}
  end
  let(:message) do
    format(
      described_class::MSG,
      name: "Commands::Spaces::Create",
      macros: "`option :actor`, `runs_as_system`, `runs_inside`, `runs_signed_out`"
    )
  end

  it "flags a command with no policy macro" do
    expect_offense(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        option :user
        def execute; end
      end
    RUBY
  end

  it "flags an empty command" do
    expect_offense(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it "flags option with a first argument other than :actor" do
    expect_offense(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        option :actor_name
      end
    RUBY
  end

  it "flags a policy macro called on a receiver" do
    expect_offense(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        self.runs_as_system
      end
    RUBY
  end

  it "flags a policy macro that only a nested class calls" do
    expect_offense(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        class Helper
          runs_as_system
        end
      end
    RUBY
  end

  it "ignores a class that is not an ApplicationCommand" do
    expect_no_offenses("class Spaces::Create < ApplicationRecord; end")
  end

  it "allows option :actor" do
    expect_no_offenses(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
        option :actor, optional: true
      end
    RUBY
  end

  %w[runs_as_system runs_inside runs_signed_out].each do |macro|
    it "allows #{macro}" do
      expect_no_offenses(<<~RUBY)
        class Commands::Spaces::Create < ApplicationCommand
          option :user
          #{macro}
        end
      RUBY
    end
  end

  it "allows a macro call with arguments" do
    expect_no_offenses(<<~RUBY)
      class Commands::Spaces::Create < ApplicationCommand
        runs_inside :space
      end
    RUBY
  end

  it "allows a rooted ApplicationCommand superclass" do
    expect_no_offenses(<<~RUBY)
      class Commands::Spaces::Create < ::ApplicationCommand
        runs_as_system
      end
    RUBY
  end

  context "with no PolicyMacros configured" do
    let(:cop_config) { {"PolicyMacros" => []} }

    it "reports nothing" do
      expect_no_offenses("class Commands::Spaces::Create < ApplicationCommand; end")
    end
  end
end
