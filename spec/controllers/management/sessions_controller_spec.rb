require 'rails_helper'

describe Management::SessionsController do

  before(:all) do
    create(:manager, username: "supermanager" , password: "secret")
  end

  describe 'Sign up' do
    it "should return 404 if not username/password" do
      expect { get :create }.to raise_error "Not Found"
    end

    it "should return 404 if wrong username" do
      expect { get :create, login: "nonexistent" , clave_usuario: "secret" }.to raise_error "Not Found"
    end

    it "should return 404 if wrong password" do
      expect { get :create, login: "supermanager" , clave_usuario: "wrong" }.to raise_error "Not Found"
    end

    it "should redirect to management root path if right credentials" do
      get :create, login: "supermanager" , clave_usuario: "secret"
      expect(response).to be_redirect
    end
  end

end