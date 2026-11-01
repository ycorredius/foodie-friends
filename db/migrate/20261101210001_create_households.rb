class CreateHouseholds < ActiveRecord::Migration[8.1]
  # Migration-local models, so this migration doesn't depend on app code.
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationHousehold < ActiveRecord::Base
    self.table_name = "households"
  end

  class MigrationMembership < ActiveRecord::Base
    self.table_name = "household_memberships"
  end

  def change
    create_table :households do |t|
      t.string :name, null: false
      # Number of people being fed; the default servings for planned meals.
      t.integer :size, null: false, default: 1

      t.timestamps
    end

    # One household per user for now; Phase 5 adds more members per household.
    create_table :household_memberships do |t|
      t.references :household, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: {unique: true}

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        MigrationUser.find_each do |user|
          household = MigrationHousehold.create!(name: "#{user.first_name}'s household")
          MigrationMembership.create!(household_id: household.id, user_id: user.id)
        end
      end
    end
  end
end
