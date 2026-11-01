# The current user's household.
class Api::V1::HouseholdsController < Api::V1::BaseController
  def show
    @household = Current.user.household
  end

  def update
    @household = Current.user.household
    if @household.update(params.expect(household: [:name, :size]))
      render :show
    else
      render json: {errors: @household.errors}, status: :unprocessable_entity
    end
  end
end
