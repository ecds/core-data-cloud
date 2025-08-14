# frozen_string_literal: true

require 'cgi'
require 'elasticsearch'
require 'rgeo'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class GeorgiaCoastMaps < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 9, collection: 'georgia_coast_maps')
        @document = document
        @record = CoreDataConnector::Place.find_by(uuid: document[:uuid])
      end

      def enhance
        @document[:manifest] = @document[:preview].first[:manifest_url] unless @document[:preview].empty?
        @document[:thumbnail_url] = thumbnail
        @document[:preview] = nil
        @document[:wms_resources] = @record.place_layers.map(&:url)
        @document[:date] = Date.strptime(@document[:year_str]).year if @document[:year_str]
        @document[:places] = places unless @document[:places].nil?
        @document[:place_names].push @document.delete(:county)
        @document[:location] = location
        @document
      end

      def iiif_thumbnail
        medium_record = CoreDataConnector::MediaContent.find_by(uuid: @document[:preview].first[:uuid])
        return if medium_record.nil?

        image = Ecds::Image.new(
          download_url: medium_record.resource_description.content_iiif_url
        )

        image.migrate
        image.versions[:thumbnail_url]
      end

      def geoserver_thumbnail
        return nil if @record.place_geometry.nil? || !@record.place_layers.first.url.include?('geoserver')

        # Zoom 17: http://wiki.openstreetmap.org/wiki/Zoom_levels
        scale = 1.193
        factory = RGeo::Geographic.simple_mercator_factory
        layer_info = CGI.parse(@record.place_layers.first.url.split('?')[1]).symbolize_keys
        workspace = layer_info[:layers].first.split(':').first
        layer = layer_info[:layers].first
        geom = @record.place_geometry.geometry
        geom_bbox = RGeo::Cartesian::BoundingBox.create_from_geometry geom
        width = factory.point(geom_bbox.min_x, geom_bbox.max_y).distance(factory.point(geom_bbox.max_x, geom_bbox.max_y)).to_f
        height = factory.point(geom_bbox.min_x, geom_bbox.min_y).distance(factory.point(geom_bbox.min_x, geom_bbox.max_y)).to_f
        x_diff = (geom_bbox.max_x - geom_bbox.min_x) * 0.35
        y_diff = (geom_bbox.max_y - geom_bbox.min_y) * 0.35
        sub_bbox = [
          geom_bbox.min_x + x_diff, geom_bbox.min_y + y_diff,
          geom_bbox.max_x - x_diff, geom_bbox.max_y - y_diff
        ]
        size = { width: (width / scale.to_f / 2).to_i, height: (height / scale.to_f / 2).to_i }
        if size[:height] > 800 || size[:width] > 800
          new_height = (size[:height].to_f / size[:width]) * 800.0
          size[:height] = new_height.round
          size[:width] = 800
        end
        # sub_bbox = sub_bbox.join(',')
        "https://geoserver.ecds.emory.edu/#{workspace}/wms?service=WMS&version=1.1.0&request=GetMap&layers=#{layer}&styles=&bbox=#{sub_bbox.join(',')}&height=#{size[:height]}&width=#{size[:width]}&srs=EPSG:4326&format=image%2Fpng"
      end

      def preview
        return preview_from_geoserver if @record.place_layers.first.url.include?('geoserver')

        return preview_from_iiif unless @document[:preview].empty?

        'https://iiif.ecds.io/iiif/3/map_placeholder.tiff/full/max/0/color.jpg'
      end

      def thumbnail
        return geoserver_thumbnail if @record.place_layers.first.url.include?('geoserver')

        return iiif_thumbnail unless @document[:preview].empty?

        'https://iiif.ecds.io/iiif/3/map_placeholder.tiff/full/max/0/color.jpg'
      end

      def location
        return { lat: 0, lon: 0 } if @record.place_geometry.nil?

        geom = @record.place_geometry.geometry
        geom = geom.first if geom.class.to_s.include? 'Collection'
        { lat: geom.centroid.y, lon: geom.centroid.x }
      end
    end
  end
end
