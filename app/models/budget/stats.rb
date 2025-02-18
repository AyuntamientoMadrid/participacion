class Budget::Stats
  include Statisticable
  alias_method :budget, :resource

  def self.stats_methods
    super + support_phase_methods + vote_phase_methods
  end

  def self.support_phase_methods
    %i[total_participants_support_phase total_budget_investments
       total_selected_investments total_unfeasible_investments headings]
  end

  def self.vote_phase_methods
    %i[total_votes total_participants_vote_phase]
  end

  def stats_methods
    base_stats_methods + participation_methods + phase_methods
  end

  def phases
    %w[support vote].select { |phase| send("#{phase}_phase_finished?") }
  end

  def all_phases
    return phases unless phases.many?

    [*phases, "every"]
  end

  def support_phase_finished?
    budget.valuating_or_later?
  end

  def vote_phase_finished?
    budget.finished?
  end

  def participation_date
    send("#{phases.last}_phase_participation_date")
  end

  def total_participants
    participants.distinct.count
  end

  def total_participants_support_phase
    voters.count
  end

  def total_participants_vote_phase
    (balloters + poll_ballot_voters).uniq.count + total_physical_balloters
  end

  def total_physical_balloters
    budget.ballots.where(physical: true).count
  end

  def total_budget_investments
    budget.investments.count
  end

  def total_supports
    supports(budget).count
  end

  def total_votes
    budget.ballots.pluck(:ballot_lines_count).sum
  end

  def total_selected_investments
    budget.investments.selected.count
  end

  def total_unfeasible_investments
    budget.investments.unfeasible.count
  end

  def headings
    groups = Hash.new(0)
    budget.headings.order("id ASC").each do |heading|
      groups[heading.id] = Hash.new(0).merge(calculate_heading_totals(heading))
    end

    groups[:total] = Hash.new(0)
    groups[:total][:total_investments_count] = groups.sum { |_k, v| v[:total_investments_count] }
    groups[:total][:total_participants_support_phase] = groups.sum { |_k, v| v[:total_participants_support_phase] }
    groups[:total][:total_participants_vote_phase] = groups.sum { |_k, v| v[:total_participants_vote_phase] }
    groups[:total][:total_participants_every_phase] = groups.sum { |_k, v| v[:total_participants_every_phase] }

    budget.headings.each do |heading|
      groups[heading.id].merge!(calculate_heading_stats_with_totals(groups[heading.id], groups[:total], heading.population))
    end

    groups[:total][:percentage_participants_support_phase] = groups.sum { |_k, v| v[:percentage_participants_support_phase] }
    groups[:total][:percentage_participants_vote_phase] = groups.sum { |_k, v| v[:percentage_participants_vote_phase] }
    groups[:total][:percentage_participants_every_phase] = groups.sum { |_k, v| v[:percentage_participants_every_phase] }

    groups
  end

  private

    def phase_methods
      phases.map { |phase| self.class.send("#{phase}_phase_methods") }.flatten
    end

    def support_phase_participation_date
      budget.phases.selecting.ends_at
    end

    def vote_phase_participation_date
      budget.phases.balloting.ends_at
    end

    def participant_ids
      phases.map { |phase| send("participant_ids_#{phase}_phase") }.flatten.uniq
    end

    def participant_ids_support_phase
      (authors + voters).uniq
    end

    def participant_ids_vote_phase
      (balloters + poll_ballot_voters).uniq
    end

    def authors
      @authors ||= budget.investments.pluck(:author_id)
    end

    def voters
      @voters ||= supports(budget).distinct.pluck(:voter_id)
    end

    def balloters
      @balloters ||= budget.ballots.where(ballot_lines_count: 1..).distinct.pluck(:user_id).compact
    end

    def poll_ballot_voters
      @poll_ballot_voters ||= budget.poll ? budget.poll.voters.pluck(:user_id) : []
    end

    def balloters_by_heading(heading_id)
      stats_cache("balloters_by_heading_#{heading_id}") do
        budget.ballots.joins(:lines)
              .where(budget_ballot_lines: { heading_id: heading_id })
              .distinct.pluck(:user_id)
      end
    end

    def voters_by_heading(heading)
      stats_cache("voters_by_heading_#{heading.id}") do
        supports(heading).distinct.pluck(:voter_id)
      end
    end

    def calculate_heading_totals(heading)
      {
        total_investments_count: heading.investments.count,
        total_participants_support_phase: voters_by_heading(heading).count,
        total_participants_vote_phase: balloters_by_heading(heading.id).count,
        total_participants_every_phase: voters_and_balloters_by_heading(heading)
      }
    end

    def calculate_heading_stats_with_totals(heading_totals, groups_totals, population)
      {
        percentage_participants_support_phase: participants_percent(heading_totals, groups_totals, :total_participants_support_phase),
        percentage_district_population_support_phase: population_percent(population, heading_totals[:total_participants_support_phase]),
        percentage_participants_vote_phase: participants_percent(heading_totals, groups_totals, :total_participants_vote_phase),
        percentage_district_population_vote_phase: population_percent(population, heading_totals[:total_participants_vote_phase]),
        percentage_participants_every_phase: participants_percent(heading_totals, groups_totals, :total_participants_every_phase),
        percentage_district_population_every_phase: population_percent(population, heading_totals[:total_participants_every_phase])
      }
    end

    def voters_and_balloters_by_heading(heading)
      (voters_by_heading(heading) + balloters_by_heading(heading.id)).uniq.count
    end

    def participants_percent(heading_totals, groups_totals, phase)
      calculate_percentage(heading_totals[phase], groups_totals[phase])
    end

    def population_percent(population, participants)
      return "N/A" unless population.to_f.positive?

      calculate_percentage(participants, population)
    end

    def supports(supportable)
      Vote.where(votable: supportable.investments)
    end

    stats_cache(*stats_methods)

    def full_cache_key_for(key)
      "budgets_stats/#{budget.id}/#{phases.join}/#{key}"
    end
end
