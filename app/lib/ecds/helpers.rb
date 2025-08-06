# frozen_string_literal: true

require 'json'
require 'rgeo'
require 'rgeo/geo_json'
require 'httparty'

module Ecds
  #
  # Helpers for indexing place records.
  #
  module Helpers
    @factory = RGeo::Geographic.spherical_factory

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

    def self.polygon_center_point(geometry)
      @factory.point(geometry.centroid.x, geometry.centroid.y)
    end

    def self.polygon_center(geometry)
      center = polygon_center_point(geometry)
      { lat: center.y, lon: center.x }
    end

    def self.line_center(geometry)
      # center = geometry.interpolate_point 0.5
      center = geometry.point_on_surface
      { lat: center.y, lon: center.x }
    end

    def self.collection_center_point(geometry)
      point = geometry.filter { |feature| feature.class.to_s.include? 'Point' }
      return @factory.point(point.first.x, point.first.y) unless point.empty?

      polygon = geometry.filter { |feature| feature.class.to_s.include? 'Polygon' }
      return polygon_center_point(polygon.first) unless polygon.empty?

      nil
    end


    def self.collection_center(geometry)
      point = geometry.filter { |feature| feature.class.to_s.include? 'Point' }
      polygon = geometry.filter { |feature| feature.class.to_s.include? 'Polygon' }
      line = geometry.filter { |feature| feature.class.to_s.include? 'Line' }
      return { lat: point.first.y, lon: point.first.x } unless point.empty?
      return polygon_center(polygon.first) unless polygon.empty?
      return line_center(line.first) unless line.empty?
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

    def self.point(geometry)
      geom_type = feature_type(geometry)
      case geom_type
      when :point
        @factory.point(geometry.x, geometry.y)
      when :polygon
        polygon_center_point(geometry)
      when :collection
        collection_center_point(geometry)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def self.geojson(record, properties)
      return if record.place_geometry.nil?

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

      geojson.deep_symbolize_keys
    end
    # rubocop:enable Metrics/MethodLength

    def self.check_for_geojson(record, document, model_mappings)
      geojson_field = model_mappings.select { |_key, value| value[:type] == 'geojson' }
      return nil if geojson_field.empty?

      property_fields = geojson_field.values.first[:property_fields].map(&:to_sym)
      properties = {}
      property_fields.each { |prop| properties[prop] = document[prop] }
      geojson(record, properties)
    end
  end
end
