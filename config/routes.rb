Rails.application.routes.draw do

  namespace :ecds do
    get 'manifest/:id/:related_model_id/:photo_uuid', to: 'combined_manifest#show'
  end
  
  mount CoreDataConnector::Engine => '/core_data'
  mount UserDefinedFields::Engine, at: '/user_defined_fields'

  # Default route for static front-end
  get '*path', to: "application#fallback_index_html", constraints: -> (request) do
    !request.xhr? && request.format.html?
  end
end
