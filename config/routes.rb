Rails.application.routes.draw do
  mount CoreDataConnector::Engine => '/core_data'
  mount JwtAuth::Engine => '/auth'

  # Default route for static front-end
  get '*path', to: "application#fallback_index_html", constraints: -> (request) do
    !request.xhr? && request.format.html?
  end
end
