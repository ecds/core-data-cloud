module Ecds
  class Osm < CoreDataConnector::Authority::Base
    include CoreDataConnector::Http::Requestable

    BASE_URL = 'https://overpass-api.de/api/interpreter'

    def find(id, type: 'way')
      # puts options[:type]
      # type = options[:type] || 'way'
      puts type
      body = "[out:json];#{type}(#{id});out geom;"
      puts body
      send_request(BASE_URL, method: :post, body:) do |response|
        JSON.parse response, symbolize_names: true
      end
    end

    def search(_, _ = {})
      puts 'not implemented'
    end

    def geojson_feature(geometries)
      coordinates = geometries.map { |geom| [geom[:lon], geom[:lat]] }
      type = coordinates.first == coordinates.last ? 'Polygon' : 'LineString'
      coordinates = type == 'Polygon' ? [coordinates] : coordinates
      {
        type: 'Feature',
        properties: {},
        geometry: {
          coordinates:,
          type:
        }
      }
    end

    def geojson_features(geometries)
      return geojson_feature(geometries) if geometries.first.instance_of?(Hash)

      geometries.map do |geometry|
        geojson_feature(geometry)
      end
    end

    def way(osm_data)
      geometries = osm_data[:elements].map { |e| e[:geometry] }
      return if geometries.empty?

      geojson_features(geometries)
    end

    def relation(osm_data)
      relations = osm_data[:elements].filter { |e| e[:type] == 'relation' }
      return if relations.empty?

      features = []
      ways = relations.map { |r| r[:members].filter { |member| member[:type] == 'way' } }.flatten
      ways.map { |m| m[:geometry] }.map { |g| g }.each do |geometries|
        # geometries.each do |geometry|
          puts geometries.count
          puts geometries
        features.push(geojson_features(geometries))
        # end
      end

      features
    end

    def geojson(id, type: 'way')
      puts type
      osm_data = find(id, type:)
      features = type == 'way' ? way(osm_data) : relation(osm_data)
      {
        type: 'FeatureCollection',
        features:
      }.to_json
    end
  end
end
# CoreDataConnector::WebIdentifier.where(web_authority_id: 1).each do |wd|
#   record = CoreDataConnector::Place.find(wd.identifiable_id)
#   next unless record.project_model_id == 6
#   data = wd_auth.find(wd.identifier).deep_symbolize_keys
#   if data[:entities][wd.identifier.to_sym]
#     if data[:entities][wd.identifier.to_sym][:claims][:P402]
#       osm = data[:entities][wd.identifier.to_sym][:claims][:P402].map {|m|m[:mainsnak]}.map {|d| d[:datavalue][:value]}
#       puts osm
#       record.user_defined['48210d8d-9a9b-4dcb-855e-8bb8ae6ce979'] = osm
#       record.save
#     end
#   end
# end; nil