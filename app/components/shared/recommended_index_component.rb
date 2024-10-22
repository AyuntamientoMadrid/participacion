class Shared::RecommendedIndexComponent < ApplicationComponent
  attr_reader :recommendations, :disable_recommendations_path, :namespace
  use_helpers :current_path_with_query_params

  def initialize(recommendations, disable_recommendations_path:, namespace:)
    @recommendations = recommendations
    @disable_recommendations_path = disable_recommendations_path
    @namespace = namespace
  end

  def render?
    feature?("user.recommendations") && recommendations.present?
  end
end
