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
        @document[:places] = add_places(@document[:places]) unless @document[:tmp_places].nil?
        @document = add_extras if @document[:types].include? 'Barrier Island'
        @document[:videos] = enhance_videos(@document[:videos])
        @document[:featured_photograph] = find_featured_photograph
        @document[:featured_video] = find_featured_video
        @document[:short_description] = short_description if @document[:short_description].nil?
        @document[:topos] = collect_topos
        @document[:map_layers] = collect_map_layers
        @document
      end

      private

      def add_extras
        @document[:related_videos] = enhance_videos(collect_related_videos.flatten.uniq.compact)
        @document[:manifests].push(
          {
            label: 'combined',
            identifier: "#{ENV['HOSTNAME']}/ecds/manifest/#{@document[:uuid]}/6/0fbeaac4-45a3-4767-b9bc-7674632a8be1"
          }
        )
        other_places = []
        poly = RGeo::GeoJSON.decode(@document[:geojson][:features].find { |f| f[:geometry][:type].downcase.include? 'polygon' }.to_json)
        related_place_uuids = @document[:tmp_places].map { |p| p[:uuid] }
        CoreDataConnector::Place.where(project_model_id: @record.project_model_id).where.not(uuid: @record.uuid).each do |related_place|
          next if related_place_uuids.include? related_place.uuid

          other_places.push @documenter.to_document related_place if related_place.place_geometry.geometry.within? poly
        end
        @document[:other_places] = add_places(other_places) unless other_places.count.zero?
        @document
      end

      def collect_related_videos
        @document[:places].map do |related_place|
          place_record = CoreDataConnector::Place.find_by(uuid: related_place[:uuid])
          related_place_document = @documenter.to_document(place_record)
          related_place_document[:videos]
        end
      end

      def find_featured_photograph
        return nil if @document[:photographs].empty?

        featured_photo = @document[:photographs].find { |p| p[:featured] } || @document[:photographs].first
        medium_record = CoreDataConnector::MediaContent.find_by(uuid: featured_photo[:uuid])
        resource = medium_record.resource_description
        extract_image_url(resource)
      end

      def find_featured_video
        return nil if @document[:videos].empty?

        @document[:videos].find { |video| video[:featured] } || @document[:videos].first
      end

      def collect_topos
        return if @document[:topos].empty?

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

      def extract_image_url(resource)
        response = HTTParty.get(resource.manifest_url, format: :plain)
        manifest = JSON.parse(response, symbolize_names: true)
        canvas = manifest[:items].find { |i| i[:type] == 'Canvas' }
        page = canvas[:items].find { |p| p[:id].include?(resource.resource_id) }
        anno = page[:items].find { |a| a[:motivation] == 'painting' }
        anno[:body][:id]
      end

      def short_description
        return unless @document[:description]

        html = Nokogiri::HTML.parse @document[:description]
        paragraphs = html.xpath('//p').map do |p|
          ActionView::Base.full_sanitizer.sanitize p.text
        end
        paragraphs.join(' ')
      end
    end
  end
end
