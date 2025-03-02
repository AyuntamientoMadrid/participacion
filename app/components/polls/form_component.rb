class Polls::FormComponent < ApplicationComponent
  attr_reader :web_vote
  delegate :poll, :questions, to: :web_vote

  def initialize(web_vote)
    @web_vote = web_vote
  end
end
