# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastTopics < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 13, collection: 'georgia_coast_topics')
        @document = document
      end

      def enhance
        @document[:places] = add_places(@document[:places]) unless @document[:places].nil?
        @document[:places] = add_points unless @document[:places].nil?
        @document[:videos] = enhance_videos(@document[:videos])
        @document[:map_layers] = collect_map_layers
        @document
      end

      private

      def add_points
        places = []
        @document[:places].each do |place|
          place_record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          place[:location] =  Ecds::Helpers.find_point(place_record.place_geometry.geometry)
          places.push place
        end
        puts places
        places
      end
    end
  end
end
