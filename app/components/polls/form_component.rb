class Polls::FormComponent < ApplicationComponent
  attr_reader :questions

  def initialize(questions)
    @questions = questions
  end
end
