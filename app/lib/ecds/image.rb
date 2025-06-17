require 'uri'
require 'cgi'
require 'httparty'
require 'aws-sdk-s3'

module Ecds
  class Image
    def initialize(download_url:, prefix:)
      @prefix = prefix
      response = HTTParty.get(download_url, follow_redirects: false)
      uri = URI response.headers[:location]
      @key = uri.path
      @key.slice!(0) if @key.starts_with?('/')
      params = CGI.parse(uri.query).deep_symbolize_keys
      @filename = params['response-content-disposition'.to_sym].first.split('; ').last.split("'").last
      @iip_path = "#{prefix}/#{File.basename(@filename, '.*')}.tiff"
      @destination_key = "images/#{@iip_path}"
    end

    def versions
      {
        thumbnail_url: "#{base_url}/square/!250,250/0/default.jpg",
        full_url: "#{base_url}/full/max/0/default.jpg",
        info: "#{base_url}/info.json"
      }
    end

    def migrate
      source_bucket = Aws::S3::Bucket.new('ecds-cantaloupe')
      destination_bucket = Aws::S3::Bucket.new('ecds-iiif')
      trigger_bucket = Aws::S3::Bucket.new('readux-s3-ingest')
      source_object = source_bucket.object(@key)
      destination_object = Aws::S3::Object.new(destination_bucket.name, @destination_key)
      return if destination_object.exists? && destination_object.last_modified > source_object.last_modified

      source_object.copy_to(bucket: destination_bucket.name, key: "incoming/#{@prefix}/#{@filename}")
      upload_trigger_file(
        filename: "#{DateTime.now.to_i}.txt",
        bucket: trigger_bucket
      )
    end

    private

    def base_url
      "https://iiif.ecds.io/iiif/3/#{@iip_path}"
    end


    def upload_trigger_file(filename:, bucket:)
      File.open(filename, 'w') do |file|
        file.puts "#{@prefix}/#{@filename}"
      end
      trigger_file = Aws::S3::Object.new(bucket.name, filename)
      trigger_file.upload_file(filename)
    end
  end
end
