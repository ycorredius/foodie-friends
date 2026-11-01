# Search and filter params for recipe lists:
#   q                  full-text search (see Recipe.search)
#   meal_type          one of Recipe.meal_types
#   difficulty         one of Recipe.difficulties
#   max_total_minutes  prep + cook time at most this many minutes
#   tags               recipes having all of these tags (array or comma-separated)
#   user_id            recipes by one author
class RecipeSearch
  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = {}
    @meal_type = enum_param(:meal_type, Recipe.meal_types)
    @difficulty = enum_param(:difficulty, Recipe.difficulties)
    @max_total_minutes = minutes_param(:max_total_minutes)
    @tags = Recipe.normalize_value_for(:tags, Array(params[:tags]).flat_map { |tags| tags.to_s.split(",") })
  end

  def valid?
    errors.empty?
  end

  def apply(scope)
    scope = scope.where(user_id: @params[:user_id]) if @params[:user_id].present?
    scope = scope.search(@params[:q]) if @params[:q].present?
    scope = scope.where(meal_type: @meal_type) if @meal_type
    scope = scope.where(difficulty: @difficulty) if @difficulty
    scope = scope.ready_within(@max_total_minutes) if @max_total_minutes
    scope = scope.tagged_with_all(@tags) if @tags.any?
    scope
  end

  private

  def enum_param(name, values)
    value = @params[name].presence or return
    return value if values.key?(value)

    errors[name] = ["must be one of: #{values.keys.join(", ")}"]
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
