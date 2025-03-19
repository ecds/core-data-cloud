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
        @document[:thumbnail_url] = thumbnail_url(@document[:thumbnail_url])
        @document[:full_url] = @document[:thumbnail_url].sub('!250,250', 'max')
        @document[:places] = places unless @document[:places].nil?
        @document[:locations] = @document[:places].map { |p| p[:location] }.compact unless @document[:places].nil?
        @document
      end

      private

      def places
        @document[:places].map do |place|
          record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          geojson = Ecds::Helpers.to_geojson(record, { name: place[:name] })
          geom = RGeo::GeoJSON.decode(geojson[:features].first.to_json)
          location = Ecds::Helpers.find_point(geom.geometry)
          {
            name: record.name,
            geojson:,
            location:
          }
        end
      end
    end
  end
end
