# frozen_string_literal: true

require "pathname"
require "lint_roller"

require_relative "../cop/propitech/prefer_fail_validation"
require_relative "../cop/propitech/prefer_succeed_validation"
require_relative "../cop/propitech/seed_uses_factory"
require_relative "../cop/propitech/seed_uses_container"

module RuboCop
  module BusinessLogic
    # LintRoller plugin registering Propitech's spec-writing cops.
    # Consuming repos enable it with `plugins: [business_logic]` in
    # their `.rubocop.yml`; the cop config ships in `config/default.yml`.
    class Plugin < LintRoller::Plugin
      def about
        @about ||= LintRoller::About.new(
          name: "business_logic",
          version: ::BusinessLogic::VERSION,
          homepage: "https://github.com/propitech/business_logic",
          description: "RuboCop cops enforcing Propitech's spec-writing standard."
        )
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
