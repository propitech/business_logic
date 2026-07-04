# frozen_string_literal: true

# RuboCop plugin entry point, lazily autoloaded so requiring this gem in
# an application never pulls RuboCop into the load path. RuboCop's plugin
# loader references the constant only when a consuming repo lists
# `business_logic` under `plugins:` in its `.rubocop.yml`.
module RuboCop # :nodoc:
  module BusinessLogic # :nodoc:
    autoload :Plugin, "rubocop/business_logic/plugin"
  end
end
