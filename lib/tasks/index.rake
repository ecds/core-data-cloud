# frozen_string_literal: true

require 'optparse'
require_relative '../elasticsearch/options'
require_relative '../elasticsearch/indexer'

namespace :ecds_index do
  desc 'CRUD for Elasticsearch index.'
  task create: :environment do
    options = Elasticsearch::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = ECDSElasticsearch::Indexer.new(collection: options[:collection],
                                             project_model_id: options[:project_model_id])
    indexer.create
  end

  desc 'Index records'
  task index: :environment do
    options = Elasticsearch::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = ECDSElasticsearch::Indexer.new(collection: options[:collection],
                                             project_model_id: options[:project_model_id])
    indexer.index
  end

  desc 'Update indexed records'
  task update: :environment do
    options = Elasticsearch::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = ECDSElasticsearch::Indexer.new(collection: options[:collection],
                                             project_model_id: options[:project_model_id])
    indexer.update
  end

  desc 'Delete index'
  task delete: :environment do
    options = Elasticsearch::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:delete -- --collection'
    end

    indexer = ECDSElasticsearch::Indexer.new(collection: options[:collection],
                                             project_model_id: options[:project_model_id])
    indexer.delete
  end

  desc 'Recreate index'
  task recreate: :environment do
    options = Elasticsearch::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection'
    end

    indexer = ECDSElasticsearch::Indexer.new(collection: options[:collection],
                                             project_model_id: options[:project_model_id])
    indexer.delete
    indexer.create
    indexer.index
  end
end
