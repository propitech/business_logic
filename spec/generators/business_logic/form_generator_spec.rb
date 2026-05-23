# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/form/form_generator"

RSpec.describe BusinessLogic::FormGenerator do
  setup_default_destination

  before { run_generator ["register_user"] }

  describe "form file" do
    subject { file("app/business_logic/forms/register_user.rb") }

    it { is_expected.to contain(/class Forms::RegisterUser < ApplicationForm/) }
  end

  describe "spec file" do
    subject { file("spec/business_logic/forms/register_user_spec.rb") }

    it { is_expected.to contain(/describe Forms::RegisterUser/) }
  end
end
