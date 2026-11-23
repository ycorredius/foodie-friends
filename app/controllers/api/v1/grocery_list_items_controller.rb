# Items on one of the household's saved grocery lists.
class Api::V1::GroceryListItemsController < Api::V1::BaseController
  # Adds a manual item: a name, and optionally a quantity, unit and category.
  def create
    @item = grocery_list.items.new(params.expect(item: [:name, :quantity, :unit, :category]).merge(manual: true))
    if @item.save
      @recipes_by_id = {}
      render :show, status: :created
    else
      render json: {errors: @item.errors}, status: :unprocessable_entity
    end
  end

  # Sets the item's status: to_buy, bought or have. The last change wins.
  def update
    @item = grocery_list.items.find(params[:id])
    if @item.update(params.expect(item: [:status]))
      @recipes_by_id = Recipe.visible_to(Current.user).where(id: @item.recipe_ids).select(:id, :title).index_by(&:id)
      render :show
    else
      render json: {errors: @item.errors}, status: :unprocessable_entity
    end
  end

  private

  def grocery_list
    Current.user.household.grocery_lists.find(params[:grocery_list_id])
  end
end
