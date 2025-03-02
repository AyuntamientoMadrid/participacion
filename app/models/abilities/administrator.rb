module Abilities
  class Administrator
    include CanCan::Ability

    def initialize(user)
      merge Abilities::Moderation.new(user)
      merge Abilities::SDG::Manager.new(user)

      can :restore, Comment
      cannot :restore, Comment, hidden_at: nil

      can :restore, Debate
      cannot :restore, Debate, hidden_at: nil

      can :restore, Proposal
      cannot :restore, Proposal, hidden_at: nil

      can :create, Legislation::Proposal
      can :show, Legislation::Proposal
      can :proposals, ::Legislation::Process

      can :restore, Legislation::Proposal
      cannot :restore, Legislation::Proposal, hidden_at: nil

      can :restore, Budget::Investment
      cannot :restore, Budget::Investment, hidden_at: nil

      can :restore, User
      cannot :restore, User, hidden_at: nil

      can :confirm_hide, Comment
      cannot :confirm_hide, Comment, hidden_at: nil

      can :confirm_hide, Debate
      cannot :confirm_hide, Debate, hidden_at: nil

      can :confirm_hide, Proposal
      cannot :confirm_hide, Proposal, hidden_at: nil

      can :confirm_hide, Legislation::Proposal
      cannot :confirm_hide, Legislation::Proposal, hidden_at: nil

      can :confirm_hide, Budget::Investment
      cannot :confirm_hide, Budget::Investment, hidden_at: nil

      can :confirm_hide, User
      cannot :confirm_hide, User, hidden_at: nil

      can :mark_featured, Debate
      can :unmark_featured, Debate

      can :comment_as_administrator, [Debate, Comment, Proposal, Poll, Poll::Question,
                                      Budget::Investment, Legislation::Question,
                                      Legislation::Proposal, Legislation::Annotation, Topic]

      can [:search, :create, :index, :destroy, :update], ::Administrator
      can [:search, :create, :index, :destroy], ::Moderator
      can [:search, :show, :update, :create, :index, :destroy, :summary], ::Valuator
      can [:search, :create, :index, :destroy], ::Manager
      can [:create, :read, :destroy], ::SDG::Manager
      can [:search, :index], ::User

      can :manage, Dashboard::Action

      can [:index, :read, :create, :update, :destroy], Budget
      can :publish, Budget, id: Budget.drafting.ids
      can :calculate_winners, Budget, &:reviewing_ballots?
      can :read_results, Budget do |budget|
        budget.balloting_finished? && budget.has_winning_investments?
      end

      can [:read, :create, :update, :destroy], Budget::Group
      can [:read, :create, :update, :destroy], Budget::Heading
      can [:hide, :admin_update], Budget::Investment
      can [:valuate, :comment_valuation], Budget::Investment
      cannot [:admin_update, :valuate, :comment_valuation],
             Budget::Investment, budget: { phase: "finished" }
      can [:select, :deselect], Budget::Investment do |investment|
        investment.feasible? && investment.valuation_finished? && !investment.budget.finished?
      end
      can [:mark_as_winner, :unmark_as_winner], Budget::Investment do |investment|
        investment.feasible? && investment.valuation_finished? && investment.budget.reviewing_ballots?
      end

      can :create, Budget::ValuatorAssignment

      can :read_admin_stats, Budget, &:balloting_or_later?

      can [:search, :update, :create, :index, :destroy], Banner

      can [:index, :create, :update, :destroy], Geozone

      can [:read, :create, :update, :destroy, :booth_assignments], Poll
      can [:read, :create, :update, :destroy, :available], Poll::Booth
      can [:search, :create, :index, :destroy], ::Poll::Officer
      can [:create, :destroy, :manage], ::Poll::BoothAssignment
      can [:create, :destroy], ::Poll::OfficerAssignment
      can :read, Poll::Question
      can [:create], Poll::Question do |question|
        question.poll.blank? || !question.poll.started?
      end
      can [:update, :destroy], Poll::Question do |question|
        !question.poll.started?
      end
      can [:read, :order_options], Poll::Question::Option
      can [:create, :update, :destroy], Poll::Question::Option do |option|
        can?(:update, option.question)
      end
      can :read, Poll::Question::Option::Video
      can [:create, :update, :destroy], Poll::Question::Option::Video do |video|
        can?(:update, video.option)
      end
      can [:destroy], Image do |image|
        image.imageable_type == "Poll::Question::Option" && can?(:update, image.imageable)
      end

      can :manage, SiteCustomization::Page
      can :manage, SiteCustomization::Image
      can :manage, SiteCustomization::ContentBlock
      can :manage, Widget::Card

      can :access, :ckeditor
      can :manage, Ckeditor::Picture

      can [:read, :debate, :draft_publication, :allegations, :result_publication,
           :milestones], Legislation::Process
      can [:create, :update, :destroy], Legislation::Process
      can [:manage], ::Legislation::DraftVersion
      can [:manage], ::Legislation::Question
      can [:manage], ::Legislation::Proposal
      cannot :comment_as_moderator,
             [::Legislation::Question, Legislation::Annotation, ::Legislation::Proposal]

      can [:create], Document
      can [:destroy], Document do |document|
        document.documentable_type == "Poll::Question::Option" && can?(:update, document.documentable)
      end
      can [:create, :destroy], DirectUpload

      can [:deliver], Newsletter, hidden_at: nil
      can [:manage], Dashboard::AdministratorTask

      can :manage, Setting::LocalesSettings

      can :manage, LocalCensusRecord
      can [:create, :read], LocalCensusRecords::Import

      can :manage, Cookies::Vendor

      if Rails.application.config.multitenancy && Tenant.default?
        can [:create, :read, :update, :hide, :restore], Tenant
      end
    end
  end
end
