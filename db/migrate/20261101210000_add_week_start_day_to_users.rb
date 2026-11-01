class AddWeekStartDayToUsers < ActiveRecord::Migration[8.1]
  def change
    # 0 = Sunday, 1 = Monday (see User.week_start_days).
    add_column :users, :week_start_day, :integer, null: false, default: 0
  end
end
