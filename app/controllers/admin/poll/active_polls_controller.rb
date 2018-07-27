class Admin::Poll::ActivePollsController < Admin::Poll::BaseController

  before_action :load_active_poll

  def edit
  end

  def update
    if @active_poll.update(active_poll_params)
      redirect_to admin_polls_url, notice: t("flash.actions.update.active_poll")
    else
      render :edit
    end
  end


  private

    def load_active_poll
      @active_poll = ::ActivePoll.first_or_create
    end

    def active_poll_params
      params.require(:active_poll).permit(:description)
    end

end
