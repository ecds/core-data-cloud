module Ecds
  class CombinedManifestController < ApplicationController
    def show
      # Get the main place record by UUID
      record = CoreDataConnector::Place.find_by(uuid: params[:id])

      related_places_relationship_model_id = params[:related_model_id].to_i
      photograph_relationship_uuid = params[:photo_uuid]

      #Find the photograph manifest for the main record
      photograph_manifest = record.manifests.find { |manifest| manifest.identifier.ends_with?(photograph_relationship_uuid) }

      # If no photograph manifest is found, return basic IIIF manifest
      manifest = photograph_manifest.nil? ? generate_empty_manifest(record) : JSON.parse(photograph_manifest.content, symbolize_names: true)

      # Replace the id in the manifest with the requested URL
      manifest[:id] = request.url

      # Collect related places and append their photograph items
      related_records_relationships = record.relationships.where(project_model_relationship_id: related_places_relationship_model_id)
      related_records = related_records_relationships.map { |rel| CoreDataConnector::Place.find(rel.related_record_id) }

      related_records.each do |related_record|
        related_photograph_manifest = related_record.manifests.find { |manifest| manifest.identifier.ends_with?(photograph_relationship_uuid) }

        next if related_photograph_manifest.nil?

        # Append the items from related photograph manifests to the main manifest
        manifest[:items] += JSON.parse(related_photograph_manifest.content, symbolize_names: true)[:items]
      end
      render json: manifest
    end

    private

    #Function to generate an empty manifest structure
    def generate_empty_manifest(record)
      {
        id: record.uuid,  
        type: 'Manifest',
        label: { en: [record.name] },
        items: []
      }
    end
  end
end
