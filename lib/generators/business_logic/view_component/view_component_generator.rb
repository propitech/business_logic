# frozen_string_literal: true

module BusinessLogic
  # Generates a ViewComponent in the Sidecar Pattern Extended layout that
  # view_component-contrib and the Propitech Rails apps use: one directory per
  # component holding the class, the template, the preview, and the preview's
  # example templates, with the spec mirroring the same path under spec/.
  #
  # The class is named `Component` inside a namespace module — there is no
  # `_component` suffix on the directory or the class, and no `_preview` suffix
  # on the preview.
  class ViewComponentGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    argument :attributes, type: :array, default: [], banner: "attribute"

    class_option :skip_test, type: :boolean, default: false
    class_option :skip_preview, type: :boolean, default: false

    def create_component_file
      template "component.rb.erb.tt", "#{component_path}/component.rb"
      template "component.html.erb.tt", "#{component_path}/component.html.erb"
    end

    def create_preview_files
      return if options[:skip_preview]

      template "preview.rb.erb.tt", "#{component_path}/preview.rb"
      template "preview_example.html.erb.tt", "#{component_path}/preview/default.html.erb"
    end

    def create_spec_file
      return if options[:skip_test]

      template "component_spec.rb.erb.tt", "spec/components/#{namespaced_path}/component_spec.rb"
    end

    private

    def component_path
      "app/components/#{namespaced_path}"
    end

    def namespaced_path
      File.join(class_path, file_name)
    end

    def component_class
      "#{class_name}::Component"
    end

    # The namespace modules the component nests in, outermost first.
    def namespace_parts
      class_name.split("::")
    end

    def options_declaration
      attributes.map { |attribute| "option :#{attribute.name}" }
    end

    # Placeholder keyword arguments for the preview and the spec. `nil` is a
    # deliberately wrong value: it names every option the component requires and
    # leaves the developer to supply real ones.
    def placeholder_arguments
      attributes.map { |attribute| "#{attribute.name}: nil" }.join(", ")
    end
  end
end
