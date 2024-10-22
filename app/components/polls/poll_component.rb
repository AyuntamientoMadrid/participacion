class Polls::PollComponent < ApplicationComponent
  attr_reader :poll
  use_helpers :can?

  def initialize(poll)
    @poll = poll
  end

  private

    def dates
      t("polls.dates", open_at: l(poll.starts_at.to_date), closed_at: l(poll.ends_at.to_date))
    end

    def link_to_poll(text, poll, options = {})
      if can?(:results, poll)
        link_to text, results_poll_path(id: poll.slug || poll.id), options
      elsif can?(:stats, poll)
        link_to text, stats_poll_path(id: poll.slug || poll.id), options
      else
        link_to text, poll_path(id: poll.slug || poll.id), options
      end
    end
end
