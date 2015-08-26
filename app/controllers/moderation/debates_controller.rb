class Moderation::DebatesController < Moderation::BaseController
  before_filter :set_valid_filters, only: :index
  before_filter :parse_filter, only: :index
  before_filter :load_debates, only: :index

  load_and_authorize_resource

  def index
    @debates = @debates.send(@filter)
    @debates = @debates.page(params[:page])
  end

  def hide
    @debate.hide
  end

  def hide_in_moderation_screen
    @debate.hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def archive
    @debate.archive
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

    def load_debates
      @debates = Debate.accessible_by(current_ability, :hide).flagged_as_inappropiate.sorted_for_moderation
    end

    def set_valid_filters
      @valid_filters = %w{all pending archived}
    end

    def parse_filter
      @filter = params[:filter]
      @filter = 'all' unless @valid_filters.include?(@filter)
    end

end
