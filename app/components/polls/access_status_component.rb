class Polls::AccessStatusComponent < ApplicationComponent
  attr_reader :poll
  use_helpers :cannot?, :current_user

  def initialize(poll)
    @poll = poll
  end
end
