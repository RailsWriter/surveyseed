Rails.application.routes.draw do

  root 'leads#home'
  
  post '/networks/login', '/networks/create'
  post '/center/addPanelistAction'
  post 'users/getEmail', 'users/savePreferences', 'users/login', 'center/draft_survey', 'users/capturefp', 'users/eval_age', 'users/sign_tos', 'users/gender', 'users/country', 'users/zip_US', 'users/zip_CA', 'users/zip_IN', 'users/zip_AU', 'users/ethnicity_US', 'users/ethnicity_CA', 'users/ethnicity_IN', 'users/race_US', 'users/race_CA', 'users/race_IN', 'users/education_US', 'users/education_CA', 'users/education_IN', 'users/education_AU', 'users/householdincome_US', 'users/householdincome_CA', 'users/householdincome_IN', 'users/householdincome_AU', 'users/householdcomp', 'users/employment', 'users/trap_question_1', 'users/trap_question_2a_US', 'users/trap_question_2a_CA', 'users/trap_question_2a_IN', 'users/trap_question_2b', 'users/personalindustry', 'users/pleasewait', 'users/p1action', 'users/p2action', 'users/p25action', 'users/p26action', 'users/p3action', 'users/jobtitleaction', 'users/childrenaction', 'users/industriesaction', 'users/Scrnr1Action', 'users/Pii1Action', 'users/join_panel'

  get 'networks/login'
  get 'center/addPanelist'
  get 'leads/panelSignUp', 'redirects/successfulPanelist', 'redirects/failurePanelist', 'users/successfulPanelist', 'users/nosuccessPanelist', 'users/alreadyPanelist', 'users/moreSurveys', 'users/qq12Returning', 'users/newCharity', '/users/successfulCharity', 'users/surveyStats', 'users/thanks', 'users/Scrnr1', 'users/Pii1', 'users/tos', 'users/qq2', 'users/qq3', 'users/qq4_US', 'users/qq4_CA', 'users/qq4_IN', 'users/qq4_AU', 'users/qq5_US', 'users/qq5_CA', 'users/qq5_IN', 'users/qq6_US', 'users/qq6_CA', 'users/qq6_IN', 'users/qq7_US', 'users/qq7_CA', 'users/qq7_IN', 'users/qq7_AU', 'users/qq8_US', 'users/qq8_CA', 'users/qq8_IN', 'users/qq8_AU', 'users/qq9', 'users/qq10', 'users/tq1', 'users/tq2a_US', 'users/tq2a_CA', 'users/tq2a_IN', 'users/qq11', 'users/qq12', 'users/tq2b', 'users/default', 'users/nosuccess', 'users/overquota', 'users/qterm', '/users/24hrsquotaexceeded', '/users/testattemptsmaxd', '/users/techtrendssamplesurvey', '/users/p2', '/users/p25', '/users/p26', '/users/p3', '/users/successful', 'redirects/status', 'redirects/default', 'redirects/success', 'redirects/failure', 'redirects/overquota', 'redirects/qterm', 'users/PrivacyPolicy', 'center/surveys_US','center/show_surveys_US', 'center/surveys_AU','center/show_surveys_AU', 'center/surveys_CA','center/show_surveys_CA', 'center/surveys_IN', 'center/show_surveys_IN', 'center/users_US', 'center/show_users_US', 'center/users_AU', 'center/show_users_AU', 'center/users_CA', 'center/show_users_CA', 'center/users_IN', 'center/show_users_IN', 'center/panelStats', 'center/show_panelStats', 'users/qq13', 'users/qq14', 'center/show_projects_CA', 'center/RFGProjects_CA', 'center/show_projects_US', 'center/RFGProjects_US', 'center/show_projects_AU', 'center/RFGProjects_AU', 'center/adhoc_surveys', 'center/show_adhoc_surveys', 'center/show_networks', 'center/allNets', 'center/allLeads', 'users/qq15', '/users/successfulMML', 'redirects/successMML', 'networks/home', 'networks/new', 'users/PrivacyPolicy'
  
  resources :leads
  resources :users
  resources :redirects
  resources :networks
  resources :center

  get '/panel/home', :to => redirect('/panel/index.html')
  get '/panel/login', :to => redirect('/panel/index.html')

  match "*path", :to => proc {|env| [200, {
  'Access-Control-Allow-Origin' => '*',
  'Access-Control-Allow-Methods' => 'POST',
  'Access-Control-Allow-Credentials' => 'true',
  'Access-Control-Request-Method' => '*',
  'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  'Content-Type' => 'application/json'

  }, ["CORS Preflight"]] }, :via => [:options]

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
