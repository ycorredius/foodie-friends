# The current user's household's reusable week templates.
class Api::V1::PlanTemplatesController < Api::V1::BaseController
  def index
    @plan_templates = paginate(household.plan_templates.includes(:meals))
  end

  def show
    @plan_template = household.plan_templates.includes(meals: {recipe: [:user, {photo_attachment: :blob}]}).find(params[:id])
  end

  # Saves the week containing `date` as a template named `name`. Recipes the
  # user can no longer see are left out.
  def create
    attributes = params.expect(plan_template: [:name, :date])
    week = week_for(attributes[:date]) or return

    @plan_template = PlanTemplate.build_from(household: household, user: Current.user, dates: week, name: attributes[:name])
    if @plan_template.meals.empty?
      render json: {errors: {date: ["is in a week with no planned meals to save"]}}, status: :unprocessable_entity
    elsif @plan_template.save
      render :show, status: :created
    else
      render json: {errors: @plan_template.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    household.plan_templates.find(params[:id]).destroy
    head :no_content
  end

  private

  def household
    Current.user.household
  end
end
