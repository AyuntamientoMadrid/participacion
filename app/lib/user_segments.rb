class UserSegments
  def self.segments
    %w[all_users
       administrators
       all_proposal_authors
       proposal_authors
       investment_authors
       feasible_and_undecided_investment_authors
       selected_investment_authors
       winner_investment_authors
       not_supported_on_current_budget] + geozones.keys
  end

  def self.segment_name(segment)
    geozones[segment.to_s]&.name || I18n.t("admin.segment_recipient.#{segment}") if valid_segment?(segment)
  end

  def self.all_users
    User.active.where.not(confirmed_at: nil)
  end

  def self.administrators
    all_users.administrators
  end

  def self.all_proposal_authors
    author_ids(Proposal.pluck(:author_id))
  end

  def self.proposal_authors
    author_ids(Proposal.not_archived.not_retired.pluck(:author_id))
  end

  def self.investment_authors
    author_ids(current_budget_investments.pluck(:author_id))
  end

  def self.feasible_and_undecided_investment_authors
    unfeasible_and_finished_condition = "feasibility = 'unfeasible' and valuation_finished = true"
    investments = current_budget_investments.where.not(unfeasible_and_finished_condition)
    author_ids(investments.pluck(:author_id))
  end

  def self.selected_investment_authors
    author_ids(current_budget_investments.selected.pluck(:author_id))
  end

  def self.winner_investment_authors
    author_ids(current_budget_investments.winners.pluck(:author_id))
  end

  def self.not_supported_on_current_budget
    author_ids(
      User.where.not(
        id: Vote.select(:voter_id).where(votable: current_budget_investments).distinct
      )
    )
  end

  def self.valid_segment?(segment)
    segments.include?(segment.to_s)
  end

  def self.recipients(segment)
    if geozones[segment.to_s]
      all_users.where(geozone: geozones[segment.to_s])
    elsif valid_segment?(segment)
      send(segment)
    else
      User.none
    end
  end

  def self.user_segment_emails(segment)
    recipients(segment).newsletter.order(:created_at).pluck(:email).compact
  end

  private

    def self.current_budget_investments
      Budget.current.investments
    end

    def self.author_ids(author_ids)
      all_users.where(id: author_ids)
    end

    def self.geozones
      Geozone.order(:name).to_h do |geozone|
        [geozone.name.gsub(/./) { |char| character_approximation(char) }.underscore.tr(" ", "_"), geozone]
      end
    end

    def self.character_approximation(char)
      I18n::Backend::Transliterator::HashTransliterator::DEFAULT_APPROXIMATIONS[char] || char
    end
end
