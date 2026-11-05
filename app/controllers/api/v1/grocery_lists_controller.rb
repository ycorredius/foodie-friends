# The household's grocery lists. `preview` works a list out from the planned
# meals without saving it; `create` saves one (see GroceryListBuilder). Both
# take start_date and end_date (YYYY-MM-DD, inclusive, at most MAX_DAYS
# apart), or neither for the current week per the user's week start.
class Api::V1::GroceryListsController < Api::V1::BaseController
  MAX_DAYS = 31

  def index
    @grocery_lists = paginate(household.grocery_lists)
    @counts = GroceryListItem.where(grocery_list_id: @grocery_lists.map(&:id)).group(:grocery_list_id, :status).count
  end

  def show
    @grocery_list = household.grocery_lists.find(params[:id])
    set_items(@grocery_list.items)
  end

  def preview
    dates = requested_dates(params) or return

    builder = GroceryListBuilder.new(household: household, user: Current.user, dates: dates)
    @dates = dates
    @unavailable_meals_count = builder.unavailable_meals_count
    set_items(builder.items)
  end

  # Saves the list for the dates, named `name` (optional). Responds with the
  # list plus unavailable_meals_count, the meals left out because the user
  # can no longer see their recipe.
  def create
    attributes = params.fetch(:grocery_list, {}).permit(:name, :start_date, :end_date)
    dates = requested_dates(attributes) or return

    builder = GroceryListBuilder.new(household: household, user: Current.user, dates: dates)
    @grocery_list = household.grocery_lists.new(name: attributes[:name].presence, start_date: dates.first, end_date: dates.last)
    @grocery_list.items = builder.items
    if @grocery_list.save
      @unavailable_meals_count = builder.unavailable_meals_count
      set_items(@grocery_list.items)
      render :show, status: :created
    else
      render json: {errors: @grocery_list.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    household.grocery_lists.find(params[:id]).destroy
    head :no_content
  end

  private

  def household
    Current.user.household
  end

  # Items to render, and the recipes they name that the user can still see.
  def set_items(items)
    @items = items
    @recipes_by_id = Recipe.visible_to(Current.user).where(id: items.flat_map(&:recipe_ids)).select(:id, :title).index_by(&:id)
  end

  # The date range in `source`'s start_date and end_date. Renders a 422 and
  # returns nil if it's invalid.
  def requested_dates(source)
    start_date, end_date = source.values_at(:start_date, :end_date)
    return Current.user.week_containing(Date.current) if start_date.blank? && end_date.blank?

    dates = Date.iso8601(start_date.to_s)..Date.iso8601(end_date.to_s)
    if dates.count.zero?
      render_date_error("end_date must be on or after start_date")
    elsif dates.count > MAX_DAYS
      render_date_error("can span at most #{MAX_DAYS} days")
    else
      dates
    end
  rescue Date::Error
    render_date_error("start_date and end_date must both be dates like 2026-11-02")
  end

  def render_date_error(message)
    render json: {errors: {dates: [message]}}, status: :unprocessable_entity
    nil
  end
end
