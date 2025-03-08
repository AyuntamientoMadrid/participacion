require "rails_helper"

describe Polls::AnswersController do
  describe "POST create" do
    it "doesn't create duplicate records on simultaneous requests", :race_condition do
      question = create(:poll_question_multiple, :abc)
      sign_in(create(:user, :level_two))

      2.times.map do
        Thread.new do
          post :create, params: {
            question_id: question.id,
            option_id: question.question_options.find_by(title: "Answer A").id,
            format: :js
          }
        rescue ActiveRecord::RecordInvalid
        end
      end.each(&:join)

      expect(Poll::Answer.count).to eq 1
    end
  end
end
