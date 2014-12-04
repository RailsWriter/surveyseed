Rails.application.routes.draw do

  root 'leads#home'
  get 'redirects/status'
  
  post 'users/eval_age', 'users/sign_tos', 'users/gender', 'users/country', 'users/zip_US', 'users/zip_CA', 'users/zip_IN', 'users/ethnicity_US', 'users/ethnicity_CA', 'users/ethnicity_IN', 'users/race_US', 'users/race_CA', 'users/race_IN', 'users/education_US', 'users/education_CA', 'users/education_IN', 'users/householdincome_US', 'users/householdincome_CA', 'users/householdincome_IN', 'users/householdcomp', 'users/trap_question_1', 'users/trap_question_2a_US', 'users/trap_question_2a_CA', 'users/trap_question_2a_IN', 'users/trap_question_2b' 
  get 'users/tos', 'users/qq2', 'users/qq3', 'users/qq4_US', 'users/qq4_CA', 'users/qq4_IN', 'users/qq5_US', 'users/qq5_CA', 'users/qq5_IN', 'users/qq6_US', 'users/qq6_CA', 'users/qq6_IN', 'users/qq7_US', 'users/qq7_CA', 'users/qq7_IN', 'users/qq8_US', 'users/qq8_CA', 'users/qq8_IN', 'users/qq9', 'users/tq1', 'users/tq2a_US', 'users/tq2a_CA', 'users/tq2a_IN', 'users/tq2b', 'users/default', 'users/success', 'users/failure', 'users/overquota', 'users/qterm','redirects/default', 'redirects/success', 'redirects/failure', 'redirects/overquota', 'redirects/qterm'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resources :leads
  resources :users
  # resources :redirects
  
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
