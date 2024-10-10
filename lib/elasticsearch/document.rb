# frozen_string_literal: true

require 'rgeo/geo_json'
require 'json'

module ECDSElasticsearch
  # Class to generate document for indexing
  # rubocop:disable Metrics/ClassLength
  class Document
    attr_reader :client, :collection_name

    def initialize(project_model_id:, collection_name:)
      @project_model_id = project_model_id
      @collection_name = collection_name
      mappings_file = File.read(File.join(Rails.root, 'lib', 'elasticsearch', 'mappings.json'))
      @model_mappings = JSON.parse(mappings_file, symbolize_names: true)[collection_name.to_sym][:model_fields]
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def to_document(record)
      document = {}
      @model_mappings.each_key do |model_field|
        field = @model_mappings[model_field]
        case field[:type]
        when 'string'
          document[model_field] = record.send(field[:field])
        when 'user_defined'
          document[model_field] = record.user_defined[field[:field]]
        when 'related'
          relations = CoreDataConnector::Relationship.where(
            primary_record_id: record.id,
            project_model_relationship_id: field[:related_model_id]
          )
          related_records = relations.map do |related_record|
            klass = related_record.related_record_type.constantize
            klass.find(related_record.related_record.id).send(field[:field])
          end
          related_records = related_records.first if field[:related_type] == 'string'
          document[model_field] = related_records
        when 'geo_point'
          document[model_field] = find_point(record.place_geometry.geometry)
        when 'slug'
          document[:slug] = record.send(field[:field]).parameterize
        else
          next
        end
      end
      geojson = check_for_geojson(record, document)
      document[:geojson] = geojson unless geojson.nil?
      document
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

    private

    def feature_type(geometry)
      return :point if geometry.class.to_s.include? 'Point'
      return :polygon if geometry.class.to_s.include? 'Polygon'
      return :collection if geometry.class.to_s.include? 'Collection'

      nil
    end

    def feature_collection_template
      {
        type: 'FeatureCollection',
        features: []
      }
    end

    def feature_template(_record, properties, geometry)
      {
        type: 'Feature',
        properties:,
        geometry:
      }
    end

    def polygon_center(geometry)
      center = geometry.centroid
      { lat: center.y, lon: center.x }
    end

    def collection_center(geometry)
      point = geometry.filter { |feature| feature.class.to_s.include? 'Point' }
      polygon = geometry.filter { |feature| feature.class.to_s.include? 'Polygon' }
      return { lat: point.first.y, lon: point.first.x } unless point.empty?
      return polygon_center(polygon.first) unless polygon.empty?

      nil
    end

    def find_point(geometry)
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
    def to_geojson(record, properties)
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

    def check_for_geojson(record, document)
      geojson_field = @model_mappings.select { |_key, value| value[:type] == 'geojson' }
      return nil if geojson_field.empty?

      property_fields = geojson_field.values.first[:property_fields].map(&:to_sym)
      properties = {}
      property_fields.each { |prop| properties[prop] = document[prop] }
      to_geojson(record, properties)
    end

    def nested_fields(record, fields)
      copy = record
      fields.each do |field|
        copy = copy.send(field)
      end
      copy
    end
  end
  # rubocop:enable Metrics/ClassLength
end
