class AddRecipeReferenceToCategory < ActiveRecord::Migration[6.1]
  def change
    add_reference :categories, :recipe, foreign_key: true
  end
end
