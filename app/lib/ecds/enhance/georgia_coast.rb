# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class GeorgiaCoast < Ecds::BaseEnhancer
      def initialize(document)
        super
        @factory = RGeo::Geographic.spherical_factory
      end

      def enhance_videos(videos)
        videos.map do |video|
          {
            **video,
            thumbnail_url: Ecds::Helpers.thumbnail_url(video[:provider], video[:embed_id]),
            embed_url: Ecds::Helpers.embed_url(video[:provider], video[:embed_id]),
            media_type: 'video',
            slug: video[:name].parameterize
          }
        end
      end

      def location(place)
        place_record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
        return if place_record.place_geometry.nil?
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
        full_url(medium_record)
      end

      def places
        @document[:places].map do |place|
          record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          geojson = Ecds::Helpers.geojson(record, { name: place[:name] })
          next if geojson.nil? || geojson[:features].empty?
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

      def photographs
        @document[:photographs].map do |photo|
          photo_record = CoreDataConnector::MediaContent.find_by(uuid: photo[:uuid])
          image = Ecds::Image.new(
            download_url: photo_record.resource_description.content_iiif_url
          )
          image.migrate
          {
            **photo,
            **image.versions,
            media_type: 'photograph',
            slug: photo_record.name.parameterize
          }
        end
      end

      def panos
        documentor = Ecds::Document.new(project_model_id: 19, collection: 'georgia_coast_panos')
        attrs = %i[name slug embed_url description thumbnail_url media_type uuid]
        @document[:panos].map do |pano|
          pano_record = CoreDataConnector::Item.find_by(uuid: pano)
          doc = documentor.to_document(pano_record)
          enhancer = Ecds::Enhance::GeorgiaCoastPanos.new doc
          result = enhancer.enhance
          result.each_key do |key|
            result.delete(key) unless attrs.include?(key)
          end
          result
        end
      end

      def add_places(places)
        places.map do |place|
          place_record = CoreDataConnector::Place.find_by(uuid: place[:uuid])
          featured_photograph = find_place_preview(place[:id])

          if featured_photograph.nil?
            featured_photograph = CoreDataConnector::Relationship.find_by(
              primary_record_id: place[:id],
              project_model_relationship_id: 5
            )
          end
          {
            **place,
            slug: place[:name].parameterize,
            location: location(place),
            type: find_type(place),
            description: place[:description]&.strip&.empty? ? nil : place[:description],
            featured_photograph:,
            identifiers: identifiers(place:),
            geojson: JSON.parse(place_record.place_geometry.geometry.to_json)
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
          preview = full_url(medium)
          layers.push({ wms_resource:, preview:, uuid: map_layer.uuid, name: })
        end
        layers
      end


      def thumbnail_url(media_content)
        response = HTTParty.get(
          media_content.content_thumbnail_url,
          follow_redirects: false
        )
        url_parts = response.headers[:location].split('/')
        url_parts[-4] = 'square'
        url_parts.join('/')
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT
        puts 'thumbnail_url Sleeping zzzzz'
        sleep 5
        retry
      end

      def preview_url(media_content)
        response = HTTParty.get(
          media_content.content_preview_url,
          follow_redirects: false
        )
        response.headers[:location]
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT
        puts 'preview_url Sleeping zzzzz'
        sleep 5
        retry
      end

      def full_url(media_content)
        response = HTTParty.get(
          media_content.content_preview_url,
          follow_redirects: false
        )
        url_parts = response.headers[:location].split('/')
        url_parts[-3] = 'max'

        url_parts.join('/')
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT
        puts 'full_url Sleeping zzzzz'
        sleep 5
        retry
      end

      def identifiers(place: nil)
        identifiable_place = if place
                               CoreDataConnector::Place.find_by(uuid: place[:uuid])
                             else
                               @record
                             end
        web_identifiers = []
        identifiable_place.web_identifiers.each do |wi|
          authority = wi.web_authority.source_type
          web_identifiers.push case authority
                               when 'geonames'
                                 {
                                   authority:,
                                   identifier: "https://www.geonames.org/#{wi.identifier}"
                                 }
                               when 'wikidata'
                                 {
                                   authority:,
                                   identifier: "https://www.wikidata.org/wiki/#{wi.identifier}"
                                 }
                               when 'viaf'
                                 {
                                   authority:,
                                   identifier: "https://viaf.org/en/viaf/#{wi.identifier}"
                                 }
                               end
        end
        web_identifiers
      end

      def date_modified
        @record.updated_at.iso8601
      end

      def works
        work_documenter = Ecds::Document.new(project_model_id: 17, collection: 'georgia_coast_works')
        @document[:works].map do |work|
          puts work
          work_record = CoreDataConnector::Work.find_by(uuid: work)
          work_doc = work_documenter.to_document(work_record)
          work_enhancer = Ecds::Enhance::GeorgiaCoastWorks.new(work_doc)
          work_enhancer.enhance
        end
      end

    end
  end
end


# reload!
# documenter = Ecds::Document.new(project_model_id: 6, collection: 'georgia_coast_places')
# doc = documenter.to_document(record)
# enhancer = Ecds::Enhance::GeorgiaCoastPlaces.new doc
# result = enhancer.enhance