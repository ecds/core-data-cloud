module Ecds
  class Geojson
    attr_reader :records
    def initialize(records, type)
      @records = records
      @type = type || 'places'
      mappings = {
        uuid: {
          type: 'string',
          field: 'uuid'
        },
        id: {
          type: 'string',
          field: 'id'
        },
        name: {
          type: 'string',
          field: 'name'
        },
        slug: {
          type: 'slug',
          field: 'name'
        },
        names: {
          type: 'names'
        },
        description: {
          type: 'user_defined',
          field: '159c8717-703e-40c5-a813-425578f9a8a7'
        },
        types: {
          type: 'related',
          primary: true,
          related_model_id: 3,
          related_type: 'array',
          field: 'name'
        },
        county: {
          type: 'related',
          primary: true,
          related_model_id: 31,
          related_type: 'string',
          field: 'name'
        },
        places: {
          type: 'related',
          primary: true,
          related_model_id: 6,
          related_type: 'hash',
          field: %w[name uuid 159c8717-703e-40c5-a813-425578f9a8a7 id]
        },
        photographs: {
          type: 'related',
          primary: true,
          related_model_id: 5,
          related_type: 'hash',
          field: %w[name uuid],
          related_fields: ['b5130e6d-2783-4f3e-b8c1-219ae5b64ee2']
        },
      }
      @documenter = Ecds::Document.new(project_model_id: 6, mappings:)
      @osm_rel_model = CoreDataConnector::ProjectModelRelationship.find(57)
    end

    def feature_collection
      collection = {
        type: 'FeatureCollection',
        features: @records.map do |record|
          next unless record.is_a? CoreDataConnector::Place

          doc = @documenter.to_document(record)
          enhancer = Enhance::GeorgiaCoastPmtiles.new(doc)
          doc = enhancer.enhance
          fc = Ecds::Helpers.check_for_geojson(
            record,
            doc,
            {
              geojson:
                {
                  type: 'geojson',
                  property_fields: %w[id uuid name types slug description featured_photograph]
                }
            }
          )
          features = fc[:features].flatten.uniq
          features.each { |feature| feature[:properties][:class] = osm_class(record) }
          place_names = CoreDataConnector::PlaceName.where(name: record.name).filter { |pn| pn.place.project_model_id == 6 }
          if place_names.count > 1
            features.each { |feature| feature[:properties][:slug] = "#{record.name} #{doc[:county]}".parameterize }
          end
          features
        end
      }
      collection[:features].flatten.uniq
    end

    def write_geojson(path: "./#{@type}.json")
      File.write(path, JSON.dump({ type: 'FeatureCollection', features: feature_collection }))
      File.exist? path
    end

    private

    def osm_class(record)
      osm_item = CoreDataConnector::Relationship.find_by(
        project_model_relationship: @osm_rel_model,
        related_record: record
      )
      return @type.singularize if osm_item.nil?

      osm_props = JSON.parse(
        osm_item.primary_record.user_defined['8f35ead2-fa02-4273-8c21-90fea494f362']
      )
      osm_props['place'] || osm_props['water'] || osm_props['waterway'] || osm_props['natural']
    end
  end
end
