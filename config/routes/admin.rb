namespace :admin do
  root to: "dashboard#index"

  resources :administrators, only: [:index, :create, :destroy, :edit, :update] do
    get :search, on: :collection
  end

  resources :tenants, except: [:show, :destroy] do
    member do
      put :hide
      put :restore
    end
  end

  constraints lambda { |request| !Rails.application.multitenancy_management_mode? } do
    resources :organizations, only: :index do
      get :search, on: :collection
      member do
        put :verify
        put :reject
      end
    end

    resources :hidden_users, only: [:index, :show] do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :hidden_budget_investments, only: :index do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :hidden_debates, only: :index do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :debates, only: [:index, :show]

    resources :proposals, only: [:index, :show, :update] do
      member do
        patch :select
        patch :deselect
      end

      resources :milestones, controller: "proposal_milestones"
      resources :progress_bars, except: :show, controller: "proposal_progress_bars"
    end

    resources :hidden_proposals, only: :index do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :hidden_proposal_notifications, only: :index do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :budgets, except: [:create, :new] do
      member do
        patch :publish
        put :calculate_winners
      end

      resources :groups, except: [:index, :show], controller: "budget_groups" do
        resources :headings, except: [:index, :show], controller: "budget_headings"
      end

      resources :budget_investments, only: [:index, :show, :edit, :update] do
        member do
          patch :select
          patch :deselect
          patch :show_to_valuators
          patch :hide_from_valuators
          patch :mark_as_winner
          patch :unmark_as_winner
        end

        resources :audits, only: :show, controller: "budget_investment_audits"
        resources :milestones, controller: "budget_investment_milestones"
        resources :progress_bars, except: :show, controller: "budget_investment_progress_bars"
      end

      resources :budget_phases, only: [:edit, :update] do
        member do
          patch :enable
          patch :disable
        end
      end
    end

    namespace :budgets_wizard do
      resources :budgets, only: [:create, :new, :edit, :update] do
        resources :groups, only: [:index, :create, :edit, :update, :destroy] do
          resources :headings, only: [:index, :create, :edit, :update, :destroy]
        end

        resources :phases, as: "budget_phases", only: [:index, :edit, :update] do
          member do
            patch :enable
            patch :disable
          end
        end
      end
    end

    resources :milestone_statuses, only: [:index, :new, :create, :update, :edit, :destroy]

    resources :signature_sheets, only: [:index, :new, :create, :show]

    resources :banners, only: [:index, :new, :create, :edit, :update, :destroy] do
      collection { get :search }
    end

    resources :hidden_comments, only: :index do
      member do
        put :restore
        put :confirm_hide
      end
    end

    resources :comments, only: :index

    resources :tags, only: [:index, :create, :update, :destroy]

    resources :officials, only: [:index, :edit, :update, :destroy] do
      get :search, on: :collection
    end

    resources :settings, only: [:index, :update]
    put :update_map, to: "settings#update_map"
    put :update_content_types, to: "settings#update_content_types"

    resources :moderators, only: [:index, :create, :destroy] do
      get :search, on: :collection
    end

    resources :valuators, only: [:show, :index, :edit, :update, :create, :destroy] do
      get :search, on: :collection
      get :summary, on: :collection
    end

    resources :valuator_groups

    resources :managers, only: [:index, :create, :destroy] do
      get :search, on: :collection
    end

    namespace :sdg do
      resources :managers, only: [:index, :create, :destroy]
    end

    resources :users, only: [:index, :show]

    scope module: :poll do
      resources :polls do
        get :booth_assignments, on: :collection

        resources :booth_assignments, only: [:index, :show, :create, :destroy] do
          get :search_booths, on: :collection
          get :manage, on: :collection
        end

        resources :officer_assignments, only: [:index, :create, :destroy] do
          get :search_officers, on: :collection
          get :by_officer, on: :collection
        end

        resources :recounts, only: :index
        resources :results, only: :index
      end

      resources :officers, only: [:index, :new, :create, :destroy] do
        get :search, on: :collection
      end

      resources :booths do
        get :available, on: :collection

        resources :shifts do
          get :search_officers, on: :collection
        end
      end

      resources :questions, shallow: true do
        resources :options, except: [:index, :show], controller: "questions/options", shallow: false
        resources :options, only: [], controller: "questions/options" do
          resources :images, controller: "questions/options/images"
          resources :videos, controller: "questions/options/videos", shallow: false
          resources :documents, only: [:index, :create], controller: "questions/options/documents"
        end
        post "/options/order_options", to: "questions/options#order_options"
      end

      resource :active_polls, only: [:create, :edit, :update]
    end

    resources :verifications, controller: :verifications, only: :index do
      get :search, on: :collection
    end

    resource :activity, controller: :activity, only: :show

    resources :newsletters do
      member do
        post :deliver
      end
      get :users, on: :collection
    end

    resources :admin_notifications do
      member do
        post :deliver
      end
    end

    resources :system_emails, only: [:index] do
      get :view
      get :preview_pending
      put :moderate_pending
      put :send_pending
    end

    resources :emails_download, only: :index do
      get :generate_csv, on: :collection
    end

    resource :stats, only: :show do
      get :graph, on: :member
      get :budgets, on: :collection
      get :budget_supporting, on: :member
      get :budget_balloting, on: :member
      get :proposal_notifications, on: :collection
      get :direct_messages, on: :collection
      get :polls, on: :collection
      get :sdg, on: :collection
    end

    namespace :legislation do
      resources :processes do
        resources :questions
        resources :proposals do
          member do
            patch :select
            patch :deselect
          end
        end
        resources :draft_versions
        resources :milestones
        resources :progress_bars, except: :show
        resource :homepage, only: [:edit, :update]
      end
    end

    resources :geozones, only: [:index, :new, :create, :edit, :update, :destroy]
    resource :locales, only: [:show, :update]

    namespace :site_customization do
      resources :pages, except: [:show] do
        resources :cards, except: [:show], as: :widget_cards
      end
      resources :images, only: [:index, :update, :destroy]
      resources :content_blocks, except: [:show]
      delete "/heading_content_blocks/:id", to: "content_blocks#delete_heading_content_block",
                                            as: "delete_heading_content_block"
      get "/edit_heading_content_blocks/:id", to: "content_blocks#edit_heading_content_block",
                                              as: "edit_heading_content_block"
      put "/update_heading_content_blocks/:id", to: "content_blocks#update_heading_content_block",
                                                as: "update_heading_content_block"
      resources :information_texts, only: [:index] do
        post :update, on: :collection
      end
      resources :documents, only: [:index, :new, :create, :destroy]
    end

    resource :homepage, controller: :homepage, only: [:show]

    namespace :widget do
      resources :cards
      resources :feeds, only: [:update]
    end

    namespace :dashboard do
      resources :actions, only: [:index, :new, :create, :edit, :update, :destroy]
      resources :administrator_tasks, only: [:index, :edit, :update]
    end

    resources :local_census_records
    namespace :local_census_records do
      resources :imports, only: [:new, :create, :show]
    end

    resource :machine_learning, controller: :machine_learning, only: [:show] do
      post :execute, on: :collection
      delete :cancel, on: :collection
    end

    namespace :cookies do
      resources :vendors, except: [:index, :show]
    end
  end
end

resolve "Milestone" do |milestone|
  [*resource_hierarchy_for(milestone.milestoneable), milestone]
end

resolve "ProgressBar" do |progress_bar|
  [*resource_hierarchy_for(progress_bar.progressable), progress_bar]
end

resolve "Audit" do |audit|
  [*resource_hierarchy_for(audit.associated || audit.auditable), audit]
end

resolve "Widget::Card" do |card, options|
  [*resource_hierarchy_for(card.cardable), card]
end

resolve "Budget::Group" do |group, options|
  [group.budget, :group, options.merge(id: group)]
end

resolve "Budget::Heading" do |heading, options|
  [heading.budget, :group, :heading, options.merge(group_id: heading.group, id: heading)]
end

resolve "Budget::Phase" do |phase, options|
  [phase.budget, :phase, options.merge(id: phase)]
end

resolve "Poll::Booth" do |booth, options|
  [:booth, options.merge(id: booth)]
end

resolve "Poll::BoothAssignment" do |assignment, options|
  [assignment.poll, :booth_assignment, options.merge(id: assignment)]
end

resolve "Poll::Shift" do |shift, options|
  [:booth, :shift, options.merge(booth_id: shift.booth, id: shift)]
end

resolve "Poll::Officer" do |officer, options|
  [:officer, options.merge(id: officer)]
end

resolve "Poll::Question::Option" do |option, options|
  [:question, :option, options.merge(question_id: option.question, id: option)]
end

resolve "Poll::Question::Option::Video" do |video, options|
  [:option, :video, options.merge(option_id: video.option, id: video)]
end

resolve "Legislation::DraftVersion" do |version, options|
  [version.process, :draft_version, options.merge(id: version)]
end
