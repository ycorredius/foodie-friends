class AddForkedFromToRecipes < ActiveRecord::Migration[8.1]
  def change
    # The recipe this one was copied from; cleared if the original is deleted.
    add_reference :recipes, :forked_from, foreign_key: {to_table: :recipes, on_delete: :nullify}
  end
end
