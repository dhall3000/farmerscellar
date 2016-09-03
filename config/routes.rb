Rails.application.routes.draw do  

  root 'static_pages#home'
  get 'rtauthorizations/new'
  post 'rtauthorizations/create'
  get 'test/garage_door'
  post 'test/checkout'
  get 'test/authorize'
  post 'test/capture'
  get 'test_page' => 'static_pages#test_page'
  get 'test_exception' => 'static_pages#test_exception'
  get 'm' => 'static_pages#m'
  get 'about' => 'static_pages#about'
  get 'contact' => 'static_pages#contact'
  get 'support' => 'static_pages#support'
  get 'how_things_work' => 'static_pages#how_things_work'
  get 'signup' => 'users#new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'
  post 'postings/fill' => 'postings#fill'
  get 'bulk_payments/test_masspay' => 'bulk_payments#test_masspay'
  post 'bulk_payments/test_masspay' => 'bulk_payments#test_masspay'
  get 'reference_transactions/new_ba'
  get 'reference_transactions/create_ba'
  post 'reference_transactions/create_capture'
  get 'reference_transactions/do_rtpurchase'
  get 'reference_transactions/do_bulk_purchase'
  get 'tote_items/pout'  
  post 'subscriptions/skip_dates'
  post 'pickups/toggle_garage_door'
  get 'pickups/log_out_dropsite_user'
  get 'partner_users/index'
  post 'partner_users/create'
  post 'partner_users/send_delivery_notification'
  
  resources :subscriptions, only: [:new, :create, :index, :show, :edit, :update]
  resources :producer_product_unit_commissions
  resources :products
  resources :website_settings, only: [:edit, :update]
  resources :users
  resources :account_activations, only: [:new, :create, :edit]
  resources :password_resets,     only: [:new, :create, :edit, :update]
  resources :postings
  resources :tote_items, only: [:index, :new, :create, :destroy]
  resources :authorizations, only: [:new, :create]
  resources :bulk_buys, only: [:new, :create]
  resources :checkouts, only: [:create]
  resources :bulk_purchases, only: [:new, :create]
  resources :bulk_payments, only: [:new, :create]      
  resources :access_codes, only: [:new, :create, :update]
  resources :dropsites
  resources :user_dropsites, only: [:create]
  resources :deliveries
  resources :pickups, only: [:new, :create]

  #THIS MUST BE THE LAST THING IN THIS ROUTES FILE. it's for catching bad paths and redirecting to root  
  get '*path' => redirect('/')

#  get 'static_pages/help'
#  get 'static_pages/about'
#  get 'static_pages/contact'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

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
end
