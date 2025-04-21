# frozen_string_literal: true

require 'elasticsearch'
require 'rgeo-geojson'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastPhotographs < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 1, collection: 'georgia_coast_photographs')
        @document = document
      end

      def enhance
        puts @document[:name]
        @document[:thumbnail_url] = thumbnail_url(CoreDataConnector::MediaContent.find_by(uuid: @document[:uuid]))
        @document[:full_url] = @document[:thumbnail_url].sub('!250,250', 'max')
        @document[:places] = places unless @document[:places].nil?
        @document[:location] = @document[:places].map { |p| p[:location] }.compact.first unless @document[:places].nil? || @document[:places].empty?
        @document
      end
    end
  end
end
