class DebatesController < ApplicationController
  before_action :parse_order, :parse_tag_filter, only: :index
  before_action :parse_comment_order, only: :show
  before_action :authenticate_user!, except: [:index, :show]

  load_and_authorize_resource
  respond_to :html, :js

  def index
    @debates = Debate.search(params).page(params[:page]).for_render.send("sort_by_#{@order}")
    @tags = ActsAsTaggableOn::Tag.all
    set_debate_votes(@debates)
  end

  def show
    set_debate_votes(@debate)
    @comments = @debate.root_comments.recent.page(params[:page]).for_render.send("sort_by_#{@comment_order}")
  end

  def new
    @debate = Debate.new
    load_featured_tags
  end

  def edit
    load_featured_tags
  end

  def create
    @debate = Debate.new(debate_params)
    @debate.author = current_user

    if @debate.save_with_captcha
      ahoy.track :debate_created, debate_id: @debate.id
      redirect_to @debate, notice: t('flash.actions.create.notice', resource_name: 'Debate')
    else
      load_featured_tags
      render :new
    end
  end

  def update
    @debate.assign_attributes(debate_params)
    if @debate.save_with_captcha
      redirect_to @debate, notice: t('flash.actions.update.notice', resource_name: 'Debate')
    else
      load_featured_tags
      render :edit
    end
  end

  def vote
    @debate.vote_by(voter: current_user, vote: params[:value])
    set_debate_votes(@debate)
  end

  def flag
    Flag.flag!(current_user, @debate)
    respond_with @debate, template: 'debates/_refresh_flag_actions'
  end

  def unflag
    Flag.unflag!(current_user, @debate)
    respond_with @debate, template: 'debates/_refresh_flag_actions'
  end

  private

    def debate_params
      params.require(:debate).permit(:title, :description, :tag_list, :terms_of_service, :captcha, :captcha_key)
    end

    def load_featured_tags
      @featured_tags = ActsAsTaggableOn::Tag.where(featured: true)
    end

    def parse_order
      @valid_orders = ['total_votes', 'created_at', 'likes']
      @order = @valid_orders.include?(params[:order]) ? params[:order] : 'created_at'
    end

    def parse_tag_filter
      valid_tags = ActsAsTaggableOn::Tag.all.map(&:name)
      @tag_filter = params[:tag] if valid_tags.include?(params[:tag])
    end

    def parse_comment_order
      @valid_comment_orders = ['total_votes', 'created_at', 'likes']
      @comment_order = @valid_comment_orders.include?(params[:order]) ? params[:order] : 'total_votes'
    end

end
