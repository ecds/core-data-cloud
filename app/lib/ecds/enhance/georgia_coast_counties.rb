# frozen_string_literal: true

require 'elasticsearch'
require 'nokogiri'
require 'rgeo-geojson'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast (County) Place records
    #
    class GeorgiaCoastCounties < Ecds::Enhance::GeorgiaCoastPlaces
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 25, collection: 'georgia_coast_places')
        @document = document
        @record = CoreDataConnector::Place.find_by(uuid: document[:uuid])
      end

      def enhance
        @document[:featured_photograph] = featured_photograph unless @document[:photographs].empty?
        @document[:photographs] = photographs
        @document[:map_layers] = map_layers
        @document[:types] = ['County']
        @document[:places] = add_places
        @document[:manifests] = [*@document[:manifests], combined_manifest]
        @document[:videos] = videos
        @document[:panos] = panos
        @document[:featured_video] = featured_video
        @document[:short_description] = short_description if @document[:short_description].nil?
        @document[:topos] = topos
        @document[:media_types] = media_types
        @document[:identifiers] = identifiers
        geojson
        @document[:date_modified] = date_modified
        @document
      end
    end
  end
end
