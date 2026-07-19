# frozen_string_literal: true

begin
  require_relative "lib/business_logic/version"
  version = BusinessLogic::VERSION
rescue LoadError
  version = "0.0.1"
end

Gem::Specification.new do |spec|
  spec.name = "business_logic"
  spec.version = version
  spec.authors = ["Hallelujah"]
  spec.email = ["hery@rails-royce.org"]

  spec.summary = "A Rails railtie to add business logic to your Rails app."
  spec.description = "Boilerplate and generators for adding business logic to your Rails app."
  spec.homepage = "https://github.com/propitech/business_logic"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.4"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/propitech/business_logic"
  spec.metadata["changelog_uri"] = "https://github.com/propitech/business_logic/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::BusinessLogic::Plugin"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  begin
    gemspec = File.basename(__FILE__)
    files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
      ls.readlines("\x0", chomp: true).reject do |f|
        (f == gemspec) ||
          f.start_with?(*%w[
                          bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml .qlty/ .reek.yml .yamllint.yaml
                          .markdownlint.json junit.xml
                        ])
      end
    end
  rescue StandardError
    files = []
  end

  spec.files = files
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]

  # Everything `require "business_logic"` loads unconditionally: Form needs
  # ActiveModel, BaseCommand needs dry-initializer and dry-monads. Consumers
  # that only have the gem in their Gemfile (such as qlty's sandboxed RuboCop
  # installing the cops plugin) rely on these resolving transitively.
  spec.add_dependency "activemodel", ">= 7.0"
  spec.add_dependency "dry-initializer", "~> 3.2"
  spec.add_dependency "dry-monads", "~> 1.9"
end
