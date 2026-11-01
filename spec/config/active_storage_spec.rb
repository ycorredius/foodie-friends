require "rails_helper"

RSpec.describe "Active Storage image processing" do
  # image_processing 2.x stopped depending on ruby-vips, and a dependency bump
  # once removed it silently, breaking every photo thumbnail.
  it "bundles ruby-vips for the :vips variant processor" do
    expect(Rails.application.config.active_storage.variant_processor).to eq(:vips)
    expect(Bundler.load.specs.map(&:name)).to include("ruby-vips")
  end
end
