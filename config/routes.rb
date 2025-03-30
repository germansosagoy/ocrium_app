Rails.application.routes.draw do
  resources :ocr_documents, only: [:new, :create, :show]
end
