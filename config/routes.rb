Rails.application.routes.draw do
  resources :ocr_documents, only: [:create, :show]
end
