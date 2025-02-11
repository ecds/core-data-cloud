# frozen_string_literal: true

require 'optparse'
require_relative './options'

namespace :ecds_index do
  desc 'CRUD for Elasticsearch index.'
  task create: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])
    indexer.create
  end

  desc 'Index records'
  task index: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])
    indexer.index
  end

  desc 'Update indexed records'
  task update: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])
    indexer.update
  end

  desc 'Delete index'
  task delete: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:delete -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])
    indexer.delete
  end

  desc 'Recreate index'
  task recreate: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])
    indexer.delete
    indexer.create
    indexer.index
  end

  desc 'Index/Update Single Record'
  task index_record: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection])

    indexer.index_record(options[:record_id])
  end

  desc 'Update All Indices'
  task update_all: :environment do
    mappings = File.read(File.join(Rails.root, 'app', 'lib', 'ecds', 'mappings.json'))
    collections = JSON.parse(mappings, symbolize_names: true)
    collections.each_key do |collection|
      indexer = Ecds::Indexer.new(collection: collection.to_s)
      indexer.update
    end
  end
end
