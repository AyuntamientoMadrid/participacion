class Management::BaseController < ActionController::Base
  layout 'management'

  before_action :verify_manager

  private

    def verify_manager
      raise ActionController::RoutingError.new('Not Found') unless current_manager.present?
    end

    def current_manager
      @current_manager ||= Manager.find(session["manager_id"]) if session["manager_id"]
    end

end
