require "rails_helper"

describe Officing::VotersController do
  describe "POST create" do
    it "does not create two records with two simultaneous requests", :race_condition do
      officer = create(:poll_officer)
      poll = create(:poll, officers: [officer])
      user = create(:user, :level_two)

      sign_in(officer.user)

      2.times.map do
        Thread.new do
          post :create, params: {
            voter: { poll_id: poll.id, user_id: user.id },
            format: :js
          }
        end
      end.each(&:join)

      expect(Poll::Voter.count).to eq 1
    end
  end
end
