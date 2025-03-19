# frozen_string_literal: true

require 'elasticsearch'
require 'nokogiri'
require 'httparty'
require 'uri'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastPanos < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 19, collection: 'georgia_coast_panos')
        @document = document
      end

      def enhance
        @document[:embed_url] = @document[:embed_url].strip
        @document[:thumbnail_url] = thumbnail_url
        @document[:places] = places unless @document[:places].nil?
        @document[:locations] = @document[:places].map { |p| p[:location] }.compact unless @document[:places].nil?
        @document
      end

      def thumbnail_url
        doc = Nokogiri::HTML.parse(HTTParty.get(@document[:embed_url]))
        element = doc.xpath('/html/head/link[@as="image"]').first
        url = URI(@document[:embed_url])
        pano_path = url.path.split('/').slice(1..3).join('/')
        image_path = element[:href].split('/').slice(0..1).join('/').gsub(/\d$/, 'hd_t.jpg')
        ["#{url.scheme}:/", url.host, pano_path, image_path].join('/')
      end
    end
  end
end
