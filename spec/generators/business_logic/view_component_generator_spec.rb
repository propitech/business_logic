# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/view_component/view_component_generator"

RSpec.describe BusinessLogic::ViewComponentGenerator do
  setup_default_destination

  context "with a namespaced component and options" do
    before { run_generator ["listings/card", "listing", "compact"] }

    describe "component file" do
      subject { file("app/components/listings/card/component.rb") }

      it { is_expected.to contain(/module Listings\n  module Card\n    class Component < ApplicationViewComponent/) }
      it { is_expected.to contain(/option :listing/) }
      it { is_expected.to contain(/option :compact/) }
    end

    describe "template file" do
      subject { file("app/components/listings/card/component.html.erb") }

      it { is_expected.to exist }
    end

    describe "preview file" do
      subject { file("app/components/listings/card/preview.rb") }

      it { is_expected.to contain(/class Preview < ApplicationViewComponentPreview/) }
      it { is_expected.to contain(/def default/) }
    end

    describe "preview example template" do
      subject { file("app/components/listings/card/preview/default.html.erb") }

      # The example template renders the component; it is not a copy of it.
      it { is_expected.to contain(/render Listings::Card::Component\.new\(listing: nil, compact: nil\)/) }
    end

    describe "spec file" do
      subject { file("spec/components/listings/card/component_spec.rb") }

      it { is_expected.to contain(/RSpec\.describe Listings::Card::Component, type: :component/) }
    end
  end

  context "with a single-segment component and no options" do
    before { run_generator ["banner"] }

    describe "component file" do
      subject { file("app/components/banner/component.rb") }

      it { is_expected.to contain(/module Banner\n  class Component < ApplicationViewComponent\n  end\nend/) }
    end
  end

  context "with the preview and spec skipped" do
    before { run_generator ["banner", "--skip-preview", "--skip-test"] }

    it { expect(file("app/components/banner/preview.rb")).not_to exist }
    it { expect(file("app/components/banner/preview/default.html.erb")).not_to exist }
    it { expect(file("spec/components/banner/component_spec.rb")).not_to exist }
    it { expect(file("app/components/banner/component.rb")).to exist }
  end
end
