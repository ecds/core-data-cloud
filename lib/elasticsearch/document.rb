# frozen_string_literal: true

require 'rgeo/geo_json'
require 'json'

module ECDSElasticsearch
  # Class to generate document for indexing
  # rubocop:disable Metrics/ClassLength
  class Document
    attr_reader :client, :collection

    def initialize(project_model_id:, collection:)
      @project_model_id = project_model_id
      @collection = collection
      mappings_file = File.read(File.join(Rails.root, 'lib', 'elasticsearch', 'mappings.json'))
      @model_mappings = JSON.parse(mappings_file, symbolize_names: true)[collection.to_sym][:model_fields]
    end

    def thumbnail_url(provider, embed_id)
      case provider
      when "Vimeo"
        "https://vumbnail.com/#{embed_id}.jpg"
      when "YouTube"
        "https://img.youtube.com/vi/#{embed_id}/hqdefault.jpg"
      else
        nil  # Fallback for unsupported providers
      end
    end

    def embed_url(provider, embed_id)
      case provider
      when "Vimeo"
        "https://player.vimeo.com/video/#{embed_id}"
      when "YouTube"
        "https://www.youtube.com/embed/#{embed_id}"
      else
        nil  # Fallback for unsupported providers
      end
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
          if field[:related_type] == 'string'
            related_records = relations.map do |related_record|
              # Converts string to callable class name.
              klass = related_record.related_record_type.constantize
              klass.find(related_record.related_record.id).send(field[:field])
            end
            related_records = related_records.first 
            document[model_field] = related_records
          end
          if field[:related_type] == "hash"
            document[model_field] = relations.map do |related_record|
              props = {}
              klass = related_record.related_record_type.constantize
              related_instance = klass.find(related_record.related_record.id)
            
              field[:field].each do |prop|
                if related_instance.respond_to?(prop)
                  props[prop] = related_instance.send(prop)
                else
                  user_defined_field = UserDefinedFields::UserDefinedField.find_by(uuid: prop)
                  if user_defined_field
                    props[user_defined_field.column_name] = related_instance.user_defined[prop]
                  else
                    Rails.logger.warn("Property #{prop} not found as a method or user-defined field.")
                  end
                end
              end
              props[:thumbnail_url] = thumbnail_url(props['provider'], props['embed_id'])
              props[:embed_url] = embed_url(props['provider'], props['embed_id'])
              props
            end
          end
            

        when 'geo_point'
          document[model_field] = find_point(record.place_geometry.geometry)
        when 'slug'
          document[:slug] = record.send(field[:field]).parameterize
        when 'manifest'
          document[:manifest] = CoreDataConnector::Manifest.find_by(manifestable_id: record.id)
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
