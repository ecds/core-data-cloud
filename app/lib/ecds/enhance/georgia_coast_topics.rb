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
        @document[:wordpress_id] = @document[:wordpress_id].to_i unless @document[:wordpress_id].nil?
        @document[:places] = add_places(@document[:places]) unless @document[:places].nil?
        @document[:places] = place_types unless @document[:place_types].nil?
        @document[:places] = nil if @document[:places].empty?
        @document[:photographs] = photographs unless @document[:photographs].nil?
        @document[:panos] = panos unless @document[:panos].nil?
        @document[:videos] = enhance_videos(@document[:videos])
        @document[:map_layers] = collect_map_layers
        @document
      end

      def place_types
        places = []
        @document[:place_types].each do |place_type|
          type = CoreDataConnector::Taxonomy.find_by(name: place_type)
          places = add_places(
            CoreDataConnector::Relationship.where(
              related_record: type,
              project_model_relationship_id: 3
            ).map(&:primary_record).map do |place|
              {
                name: place.name,
                uuid: place.uuid,
                description: place.user_defined['159c8717-703e-40c5-a813-425578f9a8a7'],
                id: place.id
              }
            end
          )
        end
        return places if @document[:places].nil?

        @document[:places] += places
      end

      def points
        places = []
        @document[:places].each do |place|
          place_record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          place[:location] = Ecds::Helpers.find_point(place_record.place_geometry.geometry)
          places.push place
        end
        places
      end
    end
  end
end
