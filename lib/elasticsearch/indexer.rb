# frozen_string_literal: true

require 'elasticsearch'
require 'json'
require_relative './document'

module ECDSElasticsearch
  # CRUD for Elasticserch index
  class Indexer
    # rubocop:disable Metrics/MethodLength
    def initialize(collection:, project_model_id:)
      @client = Elasticsearch::Client.new(
        host: ENV['ELASTICSEARCH_HOST'],
        api_key: ENV['ELASTICSEARCH_API_KEY'],
        retry_on_failure: true,
        transport_options: {
          request: { timeout: 20 }
        }
      )
      @collection = collection
      @project_model_id = project_model_id
      @documenter = ECDSElasticsearch::Document.new(project_model_id:, collection:)
      @mappings = File.read(File.join(Rails.root, 'lib', 'elasticsearch', 'mappings.json'))
    end
    # rubocop:enable Metrics/MethodLength

    def create
      document_mappings = JSON.parse(@mappings, symbolize_names: true)[@collection.to_sym][:mappings]

      @client.indices.create(index: @collection, body: { mappings: document_mappings })
    end

    def delete
      @client.indices.delete(index: @collection)
    end

    def index
      records = CoreDataConnector::Place.where(project_model_id: @project_model_id)
      requests = []
      records.each do |record|
        document = @documenter.to_document(record)
        requests.push({ index: { _index: @collection, _id: record.id, data: document } })
      end
      @client.bulk(body: requests)
    end

    def update
      index
      requests = []
      document_count = @client.count(index: @collection)['count']
      documents = @client.search(index: @collection, query: '*', field: 'uuid', size: document_count)
      documents['hits']['hits'].each do |hit|
        CoreDataConnector::Place.find(hit['_id'])
      rescue ActiveRecord::RecordNotFound
        requests.push({ delete: { _index: @collection, _id: hit['_id'] } })
      end
      @client.bulk(body: requests)
    end
  end
end

# body = [
#   { index:  { _index: 'books', _id: 45, data: { name: '1984', author: 'George Orwell', release_date: '1985-06-01', page_count: 328 } } },
#   { update: { _index: 'books', _id: 43, data: { doc: { page_count: 471 } } } },
#   { delete: { _index: 'books', _id: 44  } }
# ]
# client.bulk(body: body)
