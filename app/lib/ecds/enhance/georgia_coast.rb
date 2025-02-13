# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class GeorgiaCoast < Ecds::BaseEnhancer
      def enhance_videos(videos)
        videos.map do |video|
          {
            **video,
            thumbnail_url: Ecds::Helpers.thumbnail_url(video[:provider], video[:embed_id]),
            embed_url: Ecds::Helpers.embed_url(video[:provider], video[:embed_id])
          }
        end
      end

      def find_location(place)
        place_record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
        Ecds::Helpers.find_point(place_record.place_geometry.geometry)
      end

      def fetch_document(uuid, fields)
        @client.search(
          index: 'georgia_coast_places',
          body: {
            query: {
              simple_query_string: { query: uuid, fields: ['uuid'] }
            },
            _source: { includes: fields },
            size: 1
          }
        ).deep_symbolize_keys!
      end

      def find_type(place)
        place_document = fetch_document(place[:uuid], ['types'])
        return 'Unknown' if place_document[:hits][:total][:value].zero?

        place_document[:hits][:hits].first[:_source][:types].first
      end

      def add_places(tmp_places)
        tmp_places.map do |place|
          {
            **place,
            slug: place[:name].parameterize,
            location: find_location(place),
            type: find_type(place),
            description: place[:description]&.strip&.empty? ? nil : place[:description]
          }
        end
      end

      def collect_map_layers
        layers = []
        @document[:map_layers] = [] if @document[:map_layers].nil?
        map_layers = @document[:map_layers].map { |ml| CoreDataConnector::Place.find_by(uuid: ml) }
        map_layers.each do |map_layer|
          name = map_layer.place_layers.find_by(layer_type: 'raster').name
          wms_resource = map_layer.place_layers.find_by(layer_type: 'raster').url
          related_medium = map_layer.related_relationships.find_by(project_model_relationship_id: 11)
          medium = CoreDataConnector::MediaContent.find(related_medium.primary_record_id)
          preview = extract_image_url(medium.resource_description)
          layers.push({ wms_resource:, preview:, uuid: map_layer.uuid, name: })
        end
        layers
      end
    end
  end
end
