Rails.application.routes.draw do
  resources :ocr_documents, only: [ :new, :create, :show ]
  resources :ocr_documents do
    member do
      post :ask
    end
  end
end
