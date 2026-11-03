class CreatePlanTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_templates do |t|
      t.references :household, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
    add_index :plan_templates, [:household_id, :name], unique: true

    create_table :plan_template_meals do |t|
      t.references :plan_template, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: {on_delete: :cascade}
      # Day of the week, 0 = Sunday (Date#wday), so templates don't depend on
      # anyone's week start setting.
      t.integer :wday, null: false
      t.integer :meal_slot, null: false
      t.integer :servings, null: false

      t.timestamps
    end
    add_index :plan_template_meals, [:plan_template_id, :wday, :meal_slot, :recipe_id], unique: true,
      name: "index_plan_template_meals_once_per_slot"
  end
end
