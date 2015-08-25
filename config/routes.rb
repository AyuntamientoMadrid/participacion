Rails.application.routes.draw do
  devise_for :users, controllers: {
                       registrations: 'users/registrations',
                       omniauth_callbacks: 'users/omniauth_callbacks'
                     }
  devise_for :organizations, class_name: 'User',
             controllers: {
               registrations: 'organizations/registrations',
               sessions: 'devise/sessions',
             },
             skip: [:omniauth_callbacks]

  devise_scope :user do
    get :finish_signup, to: 'users/registrations#finish_signup'
    patch :do_finish_signup, to: 'users/registrations#do_finish_signup'
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  resources :debates do
    member do
      post :vote
      put :flag_as_inappropiate
      put :undo_flag_as_inappropiate
    end

    resources :comments, only: :create, shallow: true do
      member do
        post :vote
        put :flag_as_inappropiate
        put :undo_flag_as_inappropiate
      end
    end
  end

  resource :account, controller: "account", only: [:show, :update]
  resource :stats, only: [:show]

  namespace :api do
    resource :stats, only: [:show]
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :organizations, only: :index do
      member do
        put :verify
        put :reject
      end
    end

    resources :users, only: [:index, :show] do
      member { put :restore }
    end

    resources :debates, only: [:index, :show] do
      member { put :restore }
    end

    resources :comments, only: :index do
      member { put :restore }
    end

    resources :tags, only: [:index, :create, :update, :destroy]
    resources :officials, only: [:index, :edit, :update, :destroy] do
      collection { get :search}
    end

    resources :settings, only: [:index, :update]
  end

  namespace :moderation do
    root to: "dashboard#index"

    resources :users, only: [] do
      member { put :hide }
    end

    resources :debates, only: :index do
      member do
        put :hide
        put :hide_in_moderation_screen
        put :mark_as_reviewed
      end
    end

    resources :comments, only: :index do
      member do
        put :hide
        put :hide_in_moderation_screen
        put :mark_as_reviewed
      end
    end
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
