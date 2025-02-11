# frozen_string_literal: true

require 'json'
require 'rgeo/geo_json'
require 'httparty'

module Ecds
  #
  # Helpers for indexing place records.
  #
  module Helpers
    def self.thumbnail_url(provider, embed_id)
      case provider
      when 'Vimeo'
        "https://vumbnail.com/#{embed_id}.jpg"
      when 'YouTube'
        "https://img.youtube.com/vi/#{embed_id}/hqdefault.jpg"
      end
    end

    def self.embed_url(provider, embed_id)
      case provider
      when 'Vimeo'
        "https://player.vimeo.com/video/#{embed_id}"
      when 'YouTube'
        "https://www.youtube.com/embed/#{embed_id}"
      end
    end

    def self.feature_type(geometry)
      return :point if geometry.class.to_s.include? 'Point'
      return :polygon if geometry.class.to_s.include? 'Polygon'
      return :collection if geometry.class.to_s.include? 'Collection'

      nil
    end

    def self.feature_collection_template
      {
        type: 'FeatureCollection',
        features: []
      }
    end

    def self.feature_template(_record, properties, geometry)
      {
        type: 'Feature',
        properties:,
        geometry:
      }
    end

    def self.polygon_center(geometry)
      center = geometry.centroid
      { lat: center.y, lon: center.x }
    end

    def self.collection_center(geometry)
      point = geometry.filter { |feature| feature.class.to_s.include? 'Point' }
      polygon = geometry.filter { |feature| feature.class.to_s.include? 'Polygon' }
      return { lat: point.first.y, lon: point.first.x } unless point.empty?
      return polygon_center(polygon.first) unless polygon.empty?

      nil
    end

    def self.find_point(geometry)
      geom_type = feature_type(geometry)
      case geom_type
      when :point
        { lat: geometry.y, lon: geometry.x }
      when :polygon
        polygon_center(geometry)
      when :collection
        collection_center(geometry)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def self.to_geojson(record, properties)
      geojson = feature_collection_template
      feature_geometry = RGeo::GeoJSON.encode(record.place_geometry.geometry)
      type = feature_type(record.place_geometry.geometry)
      case type
      when :collection
        feature_geometry['geometries'].each do |geometry|
          feature = feature_template(record, properties, geometry)
          geojson[:features].push(feature)
        end
      else
        geometry = feature_geometry
        feature = feature_template(record, properties, geometry)
        geojson[:features].push(feature)
      end

      geojson
    end
    # rubocop:enable Metrics/MethodLength

    def self.check_for_geojson(record, document, model_mappings)
      geojson_field = model_mappings.select { |_key, value| value[:type] == 'geojson' }
      return nil if geojson_field.empty?

      property_fields = geojson_field.values.first[:property_fields].map(&:to_sym)
      properties = {}
      property_fields.each { |prop| properties[prop] = document[prop] }
      to_geojson(record, properties)
    end
  end
end
