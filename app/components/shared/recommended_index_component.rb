class Shared::RecommendedIndexComponent < ApplicationComponent
  attr_reader :recommended, :disable_recommendations_path, :namespace
  use_helpers :recommended_path, :current_path_with_query_params

  def initialize(recommended, disable_recommendations_path:, namespace:)
    @recommended = recommended
    @disable_recommendations_path = disable_recommendations_path
    @namespace = namespace
  end

  def render?
    feature?("user.recommendations") && recommended.present?
  end
end
