class Admin::Proposals::ProposalsComponent < ApplicationComponent
    attr_reader :proposals
  
    def initialize(proposals)
      @proposals = proposals
    end
  
    private
  
      def csv_params
        csv_params = params.clone.merge(format: :csv)
        csv_params = csv_params.to_unsafe_h.transform_keys(&:to_sym)
        csv_params.delete(:page)
        csv_params
      end
  end
  