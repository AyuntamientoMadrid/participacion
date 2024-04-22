class Polls::PollComponent < ApplicationComponent
  attr_reader :poll
  use_helpers :link_to_poll

  def initialize(poll)
    @poll = poll
  end

  private

    def dates
      t("polls.dates", open_at: l(poll.starts_at.to_date), closed_at: l(poll.ends_at.to_date))
    end
end
