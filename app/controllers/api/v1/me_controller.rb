class Api::V1::MeController < Api::V1::BaseController
  def show
  end

  def update
    if Current.user.update(params.expect(user: [:first_name, :last_name, :unit_system]))
      render :show
    else
      render json: {errors: Current.user.errors}, status: :unprocessable_entity
    end
  end
end
