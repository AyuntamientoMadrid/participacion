class Legislation::AnnotationsController < Legislation::BaseController
  skip_before_action :verify_authenticity_token

  before_action :authenticate_user!, only: [:create, :new_comment]
  before_action :convert_ranges_parameters, only: [:create]

  load_and_authorize_resource :process
  load_and_authorize_resource :draft_version, through: :process
  load_and_authorize_resource through: :draft_version

  has_orders %w[most_voted newest oldest], only: :show

  def index
  end

  def show
    @commentable = @annotation

    if params[:sub_annotation_ids].present?
      @sub_annotations = Legislation::Annotation.where(id: params[:sub_annotation_ids].split(","))
      annotations = [@commentable, @sub_annotations]
    else
      annotations = [@commentable]
    end

    @comment_tree = MergedCommentTree.new(annotations, params[:page], @current_order)
    set_comment_flags(@comment_tree.comments)
  end

  def create
    if !@process.allegations_phase.open? || @draft_version.final_version?
      render(json: {}, status: :not_found) && return
    end

    existing_annotation = @draft_version.annotations.find_by(
      range_start: annotation_params[:ranges].first[:start],
      range_start_offset: annotation_params[:ranges].first[:startOffset].to_i,
      range_end: annotation_params[:ranges].first[:end],
      range_end_offset: annotation_params[:ranges].first[:endOffset].to_i
    )

    @annotation = existing_annotation
    if @annotation.present?
      comment = @annotation.comments.build(body: annotation_params[:text], user: current_user)
      if comment.save
        render json: @annotation.to_json
      else
        render json: comment.errors.full_messages, status: :unprocessable_entity
      end
    else
      @annotation = @draft_version.annotations.new(annotation_params)
      @annotation.author = current_user
      if @annotation.save
        render json: @annotation.to_json
      else
        render json: @annotation.errors.full_messages, status: :unprocessable_entity
      end
    end
  end

  def search
    @annotations = @annotations.order(Arel.sql("LENGTH(quote) DESC"))
    annotations_hash = { total: @annotations.size, rows: @annotations }
    render json: annotations_hash.to_json(methods: :weight)
  end

  def comments
    @annotation = @annotations.find(params[:annotation_id])
    @comment = @annotation.comments.new
  end

  def new
    respond_to do |format|
      format.js
    end
  end

  def new_comment
    @annotation = @annotations.find(params[:annotation_id])
    @comment = @annotation.comments.new(body: params[:comment][:body], user: current_user)
    if @comment.save
      @comment = @annotation.comments.new
    end

    respond_to do |format|
      format.js { render :new_comment }
    end
  end

  private

    def annotation_params
      params
        .require(:legislation_annotation)
        .permit(allowed_params)
    end

    def allowed_params
      [:quote, :text, ranges: [:start, :startOffset, :end, :endOffset]]
    end

    def convert_ranges_parameters
      annotation = params[:legislation_annotation]
      if annotation&.[](:ranges).is_a?(String)
        params[:legislation_annotation][:ranges] = JSON.parse(annotation[:ranges])
      end
    rescue JSON::ParserError
    end
end
