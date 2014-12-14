Rails.application.routes.draw do

  get 'networks/home'

  get 'networks/new'

  root 'leads#home'
  
  post 'users/eval_age', 'users/sign_tos', 'users/gender', 'users/country', 'users/zip_US', 'users/zip_CA', 'users/zip_IN', 'users/zip_AU', 'users/ethnicity_US', 'users/ethnicity_CA', 'users/ethnicity_IN', 'users/race_US', 'users/race_CA', 'users/race_IN', 'users/education_US', 'users/education_CA', 'users/education_IN', 'users/education_AU', 'users/householdincome_US', 'users/householdincome_CA', 'users/householdincome_IN', 'users/householdincome_AU', 'users/householdcomp', 'users/trap_question_1', 'users/trap_question_2a_US', 'users/trap_question_2a_CA', 'users/trap_question_2a_IN', 'users/trap_question_2b', 'users/p1action', 'users/p2action', 'users/p3action'

  get 'users/tos', 'users/qq2', 'users/qq3', 'users/qq4_US', 'users/qq4_CA', 'users/qq4_IN', 'users/qq4_AU', 'users/qq5_US', 'users/qq5_CA', 'users/qq5_IN', 'users/qq6_US', 'users/qq6_CA', 'users/qq6_IN', 'users/qq7_US', 'users/qq7_CA', 'users/qq7_IN', 'users/qq7_AU', 'users/qq8_US', 'users/qq8_CA', 'users/qq8_IN', 'users/qq8_AU', 'users/qq9', 'users/tq1', 'users/tq2a_US', 'users/tq2a_CA', 'users/tq2a_IN', 'users/tq2b', 'users/default', 'users/success', 'users/failure', 'users/overquota', 'users/qterm', '/users/24hrsquotaexceeded', '/users/testattemptsmaxd', '/users/samplesurvey', '/users/p2', '/users/p3', '/users/successful', 'redirects/status', 'redirects/default', 'redirects/success', 'redirects/failure', 'redirects/overquota', 'redirects/qterm'

  resources :leads
  resources :users
  resources :redirects
  resources :networks


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
