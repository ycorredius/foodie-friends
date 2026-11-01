require "rails_helper"

RSpec.describe PurgeUnattachedUploadsJob, type: :job do
  include ActiveJob::TestHelper

  def create_blob(created_at: Time.current)
    ActiveStorage::Blob.create_and_upload!(io: file_fixture("photo.png").open, filename: "photo.png", content_type: "image/png")
      .tap { |blob| blob.update_columns(created_at: created_at) }
  end

  it "purges old unattached uploads and keeps recent or attached ones" do
    abandoned = create_blob(created_at: 2.days.ago)
    recent = create_blob
    attached = create_blob(created_at: 2.days.ago)
    create(:recipe).photo.attach(attached)

    perform_enqueued_jobs { described_class.perform_now }

    expect(ActiveStorage::Blob.exists?(abandoned.id)).to be(false)
    expect(ActiveStorage::Blob.where(id: [recent.id, attached.id]).count).to eq(2)
  end

  it "is scheduled to run daily in production" do
    tasks = YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production")
    expect(tasks.values).to include(a_hash_including("class" => "PurgeUnattachedUploadsJob"))
  end
end
