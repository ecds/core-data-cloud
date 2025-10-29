# frozen_string_literal: true

require 'elasticsearch'
require 'nokogiri'
require 'rgeo-geojson'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastPlaces < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 6, collection: 'georgia_coast_places')
        @document = document
        @record = CoreDataConnector::Place.find_by(uuid: document[:uuid])
      end

      def enhance
        @document[:map_layers] = map_layers unless @document[:map_layers].nil?
        @document[:places] = @document.delete(:sub_places) if @document[:types].include?('County')
        @document[:places] = add_places(@document[:places]) unless @document[:places].nil?
        if @document[:types].include? 'Barrier Island'
          related_media
          @document[:manifests] = [*@document[:manifests], combined_manifest]
          @document[:other_places] = other_places
        end
        @document[:featured_photograph] = featured_photograph unless @document[:photographs].empty?
        @document[:photographs] = photographs
        @document[:videos] = videos
        @document[:panos] = panos
        @document[:featured_video] = featured_video
        @document[:short_description] = short_description if @document[:short_description].nil?
        @document[:topos] = topos
        @document[:media_types] = media_types
        @document[:identifiers] = identifiers
        @document[:works] = works
        geojson
        @document[:date_modified] = date_modified
        @document[:slug] = slug
        @document
      end

      def combined_manifest
        {
          label: 'combined',
          identifier: "#{ENV['HOSTNAME']}/ecds/manifest/#{@document[:uuid]}/6/0fbeaac4-45a3-4767-b9bc-7674632a8be1"
        }
      end

      def other_places
        other_places = []
        poly = RGeo::GeoJSON.decode(@document[:geojson][:features].find { |f| f[:geometry][:type].downcase.include? 'polygon' }.to_json)
        related_place_uuids = @document[:places].map { |p| p[:uuid] }
        CoreDataConnector::Place.where(project_model_id: @record.project_model_id).where.not(uuid: @record.uuid).each do |related_place|
          next if related_place_uuids.include? related_place.uuid
          next if related_place.place_geometry.nil?

          other_places.push @documenter.to_document related_place if related_place.place_geometry.geometry.within? poly
        end
        add_places(other_places) unless other_places.count.zero?
      end

      def related_media
        @document[:places].each do |related_place|
          place_record = CoreDataConnector::Place.find_by(uuid: related_place[:uuid])
          related_place_document = @documenter.to_document(place_record)
          @document[:photographs] += related_place_document[:photographs]
          @document[:videos] += related_place_document[:videos]
          @document[:panos] += related_place_document[:panos]
        end
        @document
      end

      def featured_photograph
        featured_photo = @document[:photographs].find { |p| p[:featured] } || @document[:photographs].first
        medium_record = CoreDataConnector::MediaContent.find_by(uuid: featured_photo[:uuid])
        full_url(medium_record).sub('max', '600,')
      end

      def featured_video
        return nil if @document[:videos].empty?

        @document[:videos].find { |video| video[:featured] } || nil
      end

      def topos
        return if @document[:topos].nil? || @document[:topos].empty?

        topos = @document[:topos].map { |topo| CoreDataConnector::Place.find_by(uuid: topo) }
        years = topos.map do |layer|
          layer.place_layers.map(&:name)
        end
        years.flatten!
        years.uniq!
        years.sort!
        topo_records = years.map { |year| { year:, layers: [] } }
        topos.each do |topo|
          topo.place_layers.each do |layer|
            topo_record = topo_records.find { |tr| tr[:year] == layer.name }
            topo_record[:layers].push({ name: topo.name, url: layer.url, uuid: topo.uuid })
          end
        end
        topo_records
      end

      def short_description
        return "<div>#{@record.name}</div>" unless @document[:description]

        html = Nokogiri::HTML.parse @document[:description]
        paragraphs = html.xpath('//p').map do |p|
          ActionView::Base.full_sanitizer.sanitize p.text
        end
        "<div>#{paragraphs.join(' ')}</div>"
      end

      def media_types
        types = %w[Photographs Videos Panos]
        primary_records = @record.relationships.map(&:project_model_relationship).map(&:name).uniq.filter { |t| types.include? t }
        related_records = @record.related_relationships.map(&:project_model_relationship).map(&:inverse_name).uniq.filter { |t| types.include? t }
        [*primary_records, *related_records].compact.uniq
      end

      def geojson
        types = @document[:geojson][:features].map do |feature|
          feature[:geometry][:type]
        end
        return if types.include? 'Point'

        @document[:geojson][:features].push(
          {
            type: 'Feature',
            properties: {},
            geometry: {
              coordinates: [@document[:location][:lon], @document[:location][:lat]],
              type: 'Point'
            }
          }
        )
      end

      def slug
        place_names = CoreDataConnector::PlaceName.where(name: @record.name).filter { |pn| pn.place.project_model_id == 6 }
        return "#{@record.name} #{doc[:county]}".parameterize  if place_names.count > 1

        @doc[:slug]
      end
    end
  end
end
