class Polls::AccessStatusComponent < ApplicationComponent
  attr_reader :poll
  use_helpers :cannot?, :current_user

  def initialize(poll)
    @poll = poll
  end

  def render?
    html_class.present?
  end

  private

    def text
      if current_user
        if current_user.unverified?
          t("polls.index.not_logged_in")
        elsif cannot?(:answer, poll)
          t("polls.index.cant_answer")
        elsif !poll.votable_by?(current_user)
          t("polls.index.already_answer")
        end
      else
        t("polls.index.not_logged_in")
      end
    end

    def html_class
      if current_user
        if current_user.unverified?
          "unverified"
        elsif cannot?(:answer, poll)
          "cant-answer"
        elsif !poll.votable_by?(current_user)
          "already-answer"
        end
      else
        "not-logged-in"
      end
    end
end
