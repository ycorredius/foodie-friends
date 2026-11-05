# The household's grocery list for a range of dates, worked out from the
# planned meals (see GroceryListBuilder). Send start_date and end_date
# (YYYY-MM-DD, inclusive, at most MAX_DAYS apart), or neither for the current
# week per the user's week start.
class Api::V1::GroceryListsController < Api::V1::BaseController
  MAX_DAYS = 31

  def show
    dates = requested_dates
    return if performed?

    @grocery_list = GroceryListBuilder.new(household: Current.user.household, user: Current.user, dates: dates)
  end

  private

  def requested_dates
    start_date, end_date = params.values_at(:start_date, :end_date)
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
  end
end
