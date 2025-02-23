module ProposalsHelper
  def progress_bar_percentage(proposal)
    case proposal.cached_votes_up
    when 0 then 0
    when 1..Proposal.votes_needed_for_success
      (proposal.total_votes.to_f * 100 / Proposal.votes_needed_for_success).floor
    else 100
    end
  end

  def supports_percentage(proposal)
    percentage = (proposal.total_votes.to_f * 100 / Proposal.votes_needed_for_success)
    case percentage
    when 0 then "0%"
    when 0..0.1 then "0.1%"
    when 0.1..100 then number_to_percentage(percentage, strip_insignificant_zeros: true, precision: 1)
    else "100%"
    end
  end

  def namespaced_proposal_path(proposal, options = {})
    @namespace_proposal_path ||= namespace
    case @namespace_proposal_path
    when "management"
      management_proposal_path(proposal, options)
    else
      proposal_path(proposal, options)
    end
  end

  def retire_proposals_options
    Proposal::RETIRE_OPTIONS.map { |option| [t("proposals.retire_options.#{option}"), option] }
  end

  def empty_recommended_proposals_message_text(user)
    if user.interests.any?
      t("proposals.index.recommendations.without_results")
    else
      t("proposals.index.recommendations.without_interests")
    end
  end

  def author_of_proposal?(proposal)
    author_of?(proposal, current_user)
  end

  def current_editable?(proposal)
    current_user && proposal.editable_by?(current_user)
  end

  def proposals_minimal_view_path
    proposals_path(view: proposals_secondary_view)
  end

  def proposals_default_view?
    @view == "default"
  end

  def proposals_current_view
    @view
  end

  def proposals_secondary_view
    proposals_current_view == "default" ? "minimal" : "default"
  end

  def show_proposal_votes?
    params[:selected].blank?
  end

  def show_featured_proposals?
    params[:selected].blank? && @featured_proposals.present?
  end

  def show_recommended_proposals?
    params[:selected].blank? && feature?("user.recommendations") && @recommended_proposals.present?
  end
end
