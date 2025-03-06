require "rails_helper"

describe Admin::EmailsDownloadController do
  before do
    admin = create(:administrator, user: create(:user, email: "admin@consul.dev"))
    sign_in(admin.user)
  end

  describe "GET generate_csv" do
    it "sends a list of emails in a comma-separated format" do
      create(:user, email: "user@consul.dev")

      get :generate_csv, params: { users_segment: "all_users" }

      expect(response).to be_successful
      expect(response.body).to eq "admin@consul.dev,user@consul.dev"
    end

    it "sends an empty file with an invalid users_segment" do
      get :generate_csv, params: { users_segment: "invalid_segment" }

      expect(response).to be_successful
      expect(response.body).to be_empty
    end
  end
end
