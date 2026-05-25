# frozen_string_literal: true

require "business_logic/railtie"

module BusinessLogic
  # Helper methods for generators
  module Helper
    module ClassMethods # :nodoc:
      def component_name
        name.sub(/^BusinessLogic::/, "").sub(/Generator$/, "").pluralize.downcase
      end
    end

    class << self
      def included(base)
        base.extend ClassMethods
        base.source_root File.expand_path("#{base.component_name.singularize}/templates", __dir__)

        super
      end
    end

    def tests_path
      Helper.options.fetch(:tests_dir, "spec/business_logic")
    end

    def install_path
      Helper.options.fetch(:install_dir, "app/business_logic")
    end

    def component_name
      self.class.component_name
    end

    def regular_class_path
      [component_name] + super
    end

    def self.options
      BusinessLogic::Railtie.config.business_logic
    end

    module_function :tests_path, :install_path
    private_class_method :tests_path, :install_path
  end
end
