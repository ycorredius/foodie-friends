# Search and filter params for recipe lists:
#   q                  full-text search (see Recipe.search)
#   meal_type          one of Recipe.meal_types
#   difficulty         one of Recipe.difficulties
#   max_total_minutes  prep + cook time at most this many minutes
#   tags               recipes having all of these tags (array or comma-separated)
#   user_id            recipes by one author
#   sort               newest (default) or popular (most saved)
#   period             for sort=popular: week, month, year or all (default)
class RecipeSearch
  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = {}
    @meal_type = choice_param(:meal_type, Recipe.meal_types.keys)
    @difficulty = choice_param(:difficulty, Recipe.difficulties.keys)
    @sort = choice_param(:sort, %w[newest popular]) || "newest"
    @period = choice_param(:period, Recipe::POPULARITY_PERIODS.keys) || "all"
    @max_total_minutes = minutes_param(:max_total_minutes)
    @tags = Recipe.normalize_value_for(:tags, Array(params[:tags]).flat_map { |tags| tags.to_s.split(",") })
  end

  def valid?
    errors.empty?
  end

  def popular?
    @sort == "popular"
  end

  def apply(scope)
    scope = scope.where(user_id: @params[:user_id]) if @params[:user_id].present?
    scope = scope.search(@params[:q]) if @params[:q].present?
    scope = scope.where(meal_type: @meal_type) if @meal_type
    scope = scope.where(difficulty: @difficulty) if @difficulty
    scope = scope.ready_within(@max_total_minutes) if @max_total_minutes
    scope = scope.tagged_with_all(@tags) if @tags.any?
    scope = scope.by_popularity(Recipe::POPULARITY_PERIODS.fetch(@period)) if popular?
    scope
  end

  private

  def choice_param(name, choices)
    value = @params[name].presence or return
    return value if choices.include?(value)

    errors[name] = ["must be one of: #{choices.join(", ")}"]
    nil
  end

  def minutes_param(name)
    value = @params[name].presence or return
    minutes = Integer(value, exception: false)
    return minutes if minutes&.positive?

    errors[name] = ["must be a positive whole number"]
    nil
  end
end
