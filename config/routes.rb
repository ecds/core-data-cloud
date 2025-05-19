Rails.application.routes.draw do
  namespace :ecds do
    get 'media/index'
  end
  mount CoreDataConnector::Engine => '/core_data'
  mount UserDefinedFields::Engine, at: '/user_defined_fields'

  # Default route for static front-end
  get '*path', to: "application#fallback_index_html", constraints: -> (request) do
    !request.xhr? && request.format.html?
  end
end
