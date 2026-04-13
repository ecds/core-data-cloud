# frozen_string_literal: true

require 'searchkick'

timeout = 10

Searchkick.client = Elasticsearch::Client.new(
  host: ENV.fetch('ELASTICSEARCH_HOST'),
  api_key: ENV.fetch('ELASTICSEARCH_API_KEY'),
  transport_options: { request: { timeout: }, headers: { content_type: 'application/json' } },
  retry_on_failure: 2
)
