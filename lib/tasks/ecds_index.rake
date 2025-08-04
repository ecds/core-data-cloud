# frozen_string_literal: true

require 'optparse'
require_relative './options'

namespace :ecds_index do
  desc 'CRUD for Elasticsearch index.'
  task create: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])
    indexer.create
  end

  desc 'Index records'
  task index: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])
    indexer.index
  end

  desc 'Update indexed records'
  task update: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:create -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])
    indexer.update
  end

  desc 'Delete index'
  task delete: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:delete -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])
    indexer.delete
  end

  desc 'Recreate index'
  task recreate: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])
    indexer.delete
    indexer.create
    indexer.index
  end

  desc 'Index/Update Single Record'
  task index_record: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])

    indexer.index_record(options[:record_id])
  end

  desc 'Delete Single Record'
  task delete_record: :environment do
    options = Ecds::Options.parse(ARGV) do |opts|
      opts.banner = 'Usage: ecds_index:recreate -- --collection --mapping'
    end

    indexer = Ecds::Indexer.new(collection: options[:collection], mapping: options[:mapping])

    indexer.delete_record(options[:record_id])
  end

  desc 'Update All Indices'
  task update_all: :environment do
    return if File.exist?('index_updating')

    File.open('index_updating')
    begin
      mappings = File.read(File.join(Rails.root, 'app', 'lib', 'ecds', 'mappings.json'))
      collections = JSON.parse(mappings, symbolize_names: true)
      collections.each_key do |collection|
        indexer = Ecds::Indexer.new(collection: collection.to_s)
        indexer.update
      end
      CoreDataConnector::MediaContent.all.reverse.each do |medium|
        response = HTTParty.get(medium.resource_description.content_iiif_url, follow_redirects: false)
        next unless response.code == 302

        [medium.resource_description.content_download_url, medium.resource_description.content_iiif_url].each do |download_url|    
          image = Ecds::Image.new(download_url: download_url)
          image.migrate
        end
      end
    rescue StandardError => e
      puts "uncaught #{e} exception while handling connection: #{e.message}"
    end

    File.delete('index_updating')
  end
end
