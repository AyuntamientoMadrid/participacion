class Polls::ResultsComponent < ApplicationComponent
  attr_reader :poll

  def initialize(poll)
    @poll = poll
  end
end
