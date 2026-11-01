# Permanently deletes accounts deactivated longer than User::DELETION_GRACE_PERIOD,
# along with everything they own. Scheduled daily in config/recurring.yml.
class PurgeDeactivatedUsersJob < ApplicationJob
  queue_as :default

  def perform
    User.due_for_deletion.find_each(&:destroy!)
  end
end
