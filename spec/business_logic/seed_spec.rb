# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "tmpdir"

# Throwaway seeds for exercising the registry. Kept in their own namespace so
# depends_on resolves siblings by name the way a host app's Seeds:: module does.
module SeedSpec
  class Base < BusinessLogic::Seed
    def call = container.get(:ran) << self.class.name
  end

  class Author < Base
  end

  class Book < Base
    depends_on :author
  end

  class Chapter < Base
    depends_on :book
  end

  class Chicken < Base
  end

  class Egg < Base
    depends_on :chicken
  end

  Chicken.depends_on :egg
end

# A two-level chain (Leaf < Middle < Root < BusinessLogic::Seed) with its own
# abstract root, to exercise the recursive registry the way a host app's
# Seeds::Foo < AppSeed < BusinessLogic::Seed chain does.
module RegistrySpec
  class Root < BusinessLogic::Seed
  end

  class Middle < Root
    def call = nil
  end

  class Leaf < Middle
    def call = nil
  end
end

# An isolated base whose whole subtree is the seeds .run_all loads from a temp
# directory below, so the process-global registry does not leak the other
# spec seeds into this example.
module RunAllSpec
  class Base < BusinessLogic::Seed
    def call = container.get(:ran) << self.class.name.split("::").last
  end
end

RSpec.describe BusinessLogic::Seed do
  describe ".ordered" do
    it "places each dependency before the seed that needs it" do
      expect(described_class.ordered([SeedSpec::Chapter, SeedSpec::Author]))
        .to eq([SeedSpec::Author, SeedSpec::Book, SeedSpec::Chapter])
    end

    it "raises on a dependency cycle" do
      expect { described_class.ordered([SeedSpec::Chicken]) }
        .to raise_error(BusinessLogic::Seed::CircularDependencyError, /Chicken.*Egg.*Chicken/)
    end
  end

  describe ".run" do
    let(:container) do
      BusinessLogic::Seed::Container.new(output: StringIO.new).tap { |c| c.set(:ran, []) }
    end

    it "runs each seed once, dependencies first, against a shared container" do
      described_class.run([SeedSpec::Chapter], container)

      expect(container.get(:ran)).to eq(%w[SeedSpec::Author SeedSpec::Book SeedSpec::Chapter])
    end

    it "returns the container it ran against" do
      expect(described_class.run([SeedSpec::Author], container)).to be(container)
    end
  end

  describe ".run_all" do
    it "loads the seeds under dir and runs the concrete ones in dependency order" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "beta.rb"), <<~RUBY)
          module RunAllSpec
            class Beta < Base
              depends_on :alpha
            end
          end
        RUBY
        File.write(File.join(dir, "alpha.rb"), <<~RUBY)
          module RunAllSpec
            class Alpha < Base
            end
          end
        RUBY
        container = BusinessLogic::Seed::Container.new(output: StringIO.new)
        container.set(:ran, [])

        RunAllSpec::Base.run_all(container, dir: dir)

        expect(container.get(:ran)).to eq(%w[Alpha Beta])
      end
    end
  end

  describe "the concrete registry" do
    it "finds seeds at any depth below an abstract root, skipping the abstract ones" do
      expect(RegistrySpec::Root.send(:concrete_seeds))
        .to eq([RegistrySpec::Leaf, RegistrySpec::Middle])
    end
  end

  describe "#call" do
    it "raises NotImplementedError on the abstract base" do
      expect { described_class.new(BusinessLogic::Seed::Container.new).call }
        .to raise_error(NotImplementedError)
    end
  end

  describe "#say" do
    it "writes to the container's output" do
      buffer = StringIO.new

      SeedSpec::Author.new(BusinessLogic::Seed::Container.new(output: buffer)).say("hi")

      expect(buffer.string).to eq("hi\n")
    end
  end

  describe BusinessLogic::Seed::Container do
    it "stores and reads a value" do
      container = described_class.new
      container.set(:answer, 42)

      expect(container.get(:answer)).to eq(42)
    end

    it "raises when reading a missing key" do
      expect { described_class.new.get(:missing) }.to raise_error(KeyError)
    end
  end
end
