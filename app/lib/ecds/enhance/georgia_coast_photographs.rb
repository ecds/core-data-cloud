# frozen_string_literal: true

require 'elasticsearch'
require 'rgeo-geojson'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastPhotographs < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 1, collection: 'georgia_coast_photographs')
        @document = document
        @record = CoreDataConnector::MediaContent.find_by(uuid: @document[:uuid])
      end

      def enhance
        versions
        @document[:places] = places unless @document[:places].nil?
        @document[:location] = @document[:places].map { |p| p[:location] }.compact.first unless @document[:places].nil? || @document[:places].empty?
        @document
      end

      def versions
        image = Ecds::Image.new(
          download_url: @record.resource_description.content_download_url
        )
        image.migrate
        @document.merge!(image.versions)
      end
    end
  end
end
