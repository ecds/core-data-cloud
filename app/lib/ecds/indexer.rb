# frozen_string_literal: true

require 'elasticsearch'
require 'json'
# require_relative './document'

module Ecds
  # CRUD for Elasticsearch index
  class Indexer
    # rubocop:disable Metrics/MethodLength
    def initialize(collection:)
      @client = Elasticsearch::Client.new(
        host: ENV['ELASTICSEARCH_HOST'],
        api_key: ENV['ELASTICSEARCH_API_KEY'],
        retry_on_failure: true,
        transport_options: {
          request: { timeout: 20 }
        }
      )
      @collection = collection
      collections = File.read(File.join(Rails.root, 'app', 'lib', 'ecds', 'mappings.json'))
      @collection_mappings = JSON.parse(collections, symbolize_names: true)[collection.to_sym]
      @project_model_id = @collection_mappings[:project_model_id]
      project_model = CoreDataConnector::ProjectModel.find(@project_model_id)
      @model_class = project_model.model_class.constantize
      @documenter = Ecds::Document.new(project_model_id: @project_model_id, collection:)
      @enhancer_class = begin
        "Ecds::Enhance::#{collection.camelcase}".constantize
      rescue NameError
          nil
      end
    end
    # rubocop:enable Metrics/MethodLength

    def create
      document_mappings = @collection_mappings[:mappings]
      @client.indices.create(index: @collection, body: { mappings: document_mappings })
    end

    def delete
      @client.indices.delete(index: @collection)
    end

    def index
      requests = index_requests
      @client.bulk(body: requests)
    end

    def update
      requests = index_requests
      document_count = @client.count(index: @collection)['count']
      documents = @client.search(index: @collection, body: { fields: ['uuid'], size: document_count, _source: false })
      documents['hits']['hits'].each do |hit|
        record = @model_class.find(hit['_id'])
        document = @documenter.to_document(record)
        document = enhance(document) unless @enhancer_class.nil?
        requests.push({ update: { _index: @collection, _id: record.id, data: { doc: document } } })
      rescue ActiveRecord::RecordNotFound
        requests.push({ delete: { _index: @collection, _id: hit['_id'] } })
      end
      return if requests.empty?

        requests.in_groups_of(100) { |_group| @client.bulk(body: requests) }
    end

    def recreate
      delete
      create
      index
      update
    end

    def index_record(record_id)
      record = @model_class.find(record_id)
      document = @documenter.to_document(record)
      document = enhance(document) unless @enhancer_class.nil?
      begin
        @client.get(index: @collection, id: record.id)
        @client.update(index: @collection, id: record.id, body: { doc: document })
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        @client.index(index: @collection, body: document)
      end
    end

    private

    def index_requests
      document_count = @client.count(index: @collection)['count']
      documents = @client.search(index: @collection, body: { fields: ['uuid'], size: document_count, _source: false })
      hit_ids = documents['hits']['hits'].map { |h| h['_id'] }
      records = @model_class.where(project_model_id: @project_model_id)
      records = records.filter { |record| !hit_ids.include? record.id }
      records.map do |record|
        { index: { _index: @collection, _id: record.id, data: @documenter.to_document(record) } }
      end
    end

    def enhance(document)
      enhancer = @enhancer_class.new document
      enhancer.enhance
    end
  end
end

# ActiveRecord::Base.logger = nil
# record = CoreDataConnector::Place.find(3430)
# documenter = Ecds::Document.new(project_model_id: 6, collection: 'georgia_coast_places')
# document = documenter.to_document record
# enhancer = Ecds::Enhance::GeorgiaCoastPlaces.new document
# document = enhancer.enhance
