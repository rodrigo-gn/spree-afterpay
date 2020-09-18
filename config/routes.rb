Spree::Core::Engine.add_routes do
  # Add your extension routes here
  get '/afterpay', :to => "afterpay#checkout", :as => :afterpay_checkout_get
  post '/afterpay', :to => "afterpay#checkout", :as => :afterpay_checkout
  resources :afterpay, only: [] do
    member do
      get :success
      get :cancel
    end
  end

  namespace :admin do
    resources :orders, only: [] do
      resources :payments, only: [] do
        member do
          get 'afterpay_refund'
          post 'execute_afterpay_refund'
        end
      end
    end
  end

end
