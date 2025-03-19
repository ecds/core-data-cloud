# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class GeorgiaCoast < Ecds::BaseEnhancer
      def initialize(document)
        super
        @factory = RGeo::Cartesian.factory
      end

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

      def extract_image_url(resource)
        response = HTTParty.get(resource.manifest_url, format: :plain)
        manifest = JSON.parse(response, symbolize_names: true)
        canvas = manifest[:items].find { |i| i[:type] == 'Canvas' }
        page = canvas[:items].find { |p| p[:id].include?(resource.resource_id) }
        anno = page[:items].find { |a| a[:motivation] == 'painting' }
        anno[:body][:id]
      end

      # TODO: This is not universal and should not be on base class. It is shared between places and counties.
      def find_place_preview(id)
        media_relations = CoreDataConnector::Relationship.where(
          primary_record_id: id,
          project_model_relationship_id: 5
        )
        return nil if media_relations.empty?

        ud_uuid = 'b5130e6d-2783-4f3e-b8c1-219ae5b64ee2'
        has_featured = media_relations.any? { |m| m.user_defined == { ud_uuid => true } }
        medium_record = if has_featured
                          CoreDataConnector::MediaContent.find(
                            media_relations.find { |m| m.user_defined == { ud_uuid => true } }.related_record_id
                          )
                        else
                          CoreDataConnector::MediaContent.find(
                            media_relations.first.related_record_id
                          )
                        end
        extract_image_url(medium_record.resource_description)
      end

      def add_places(places)
        places.map do |place|
          preview = find_place_preview(place[:id])


          if preview.nil?
            preview = CoreDataConnector::Relationship.find_by(
              primary_record_id: place[:id],
              project_model_relationship_id: 5
            )
          end
          {
            **place,
            slug: place[:name].parameterize,
            location: find_location(place),
            type: find_type(place),
            description: place[:description]&.strip&.empty? ? nil : place[:description],
            preview:
          }
        end
      end

      def collect_map_layers
        layers = []
        @document[:map_layers] = [] if @document[:map_layers].nil?
        map_layers = @document[:map_layers].map { |ml| CoreDataConnector::Place.find_by(uuid: ml) }
        map_layers.each do |map_layer|
          next if map_layer.nil?
          name = map_layer.place_layers.find_by(layer_type: 'raster').name
          wms_resource = map_layer.place_layers.find_by(layer_type: 'raster').url
          related_medium = map_layer.related_relationships.find_by(project_model_relationship_id: 11)
          medium = CoreDataConnector::MediaContent.find(related_medium.primary_record_id)
          preview = extract_image_url(medium.resource_description)
          layers.push({ wms_resource:, preview:, uuid: map_layer.uuid, name: })
        end
        layers
      end

      def thumbnail_url(url)
        response = HTTParty.get(
          url,
          follow_redirects: false
        )
        response.headers[:location].sub('square', 'full')
      end

      def places
        @document[:places].map do |place|
          record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          point = Ecds::Helpers.find_point(record.place_geometry.geometry)
          record.place_geometry.geometry = @factory.point(*point.values)
          geojson = Ecds::Helpers.to_geojson(record, { name: place[:name] })
          geom = RGeo::GeoJSON.decode(geojson[:features].first.to_json)
          location = Ecds::Helpers.find_point(geom.geometry)
          {
            name: place[:name],
            uuid: place[:uuid],
            geojson:,
            location:
          }
        end
      end

    end
  end
end
