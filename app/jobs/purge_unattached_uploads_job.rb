# Deletes direct uploads that were never attached to a record (abandoned or
# rejected uploads). Scheduled daily in config/recurring.yml.
class PurgeUnattachedUploadsJob < ApplicationJob
  queue_as :default

  # Long enough for a client to finish uploading and attach the file.
  GRACE_PERIOD = 1.day

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ..GRACE_PERIOD.ago).find_each(&:purge_later)
  end
end
