class AddDuplicateAndEditProtectionToPlannedMeals < ActiveRecord::Migration[8.1]
  def change
    # A recipe can be planned once per household, date and meal slot, so a
    # repeated add (double tap, retry) can't create duplicates.
    add_index :planned_meals, [:household_id, :date, :meal_slot, :recipe_id], unique: true,
      name: "index_planned_meals_once_per_slot"

    # Optimistic locking: edits must send the version they last saw, so
    # simultaneous edits don't silently overwrite each other.
    add_column :planned_meals, :lock_version, :integer, null: false, default: 0
  end
end
