# frozen_string_literal: true

require 'cgi'
require 'elasticsearch'
require 'rgeo'

module Ecds
  module Enhance
    #
    # Base enhancer for Georgia Coast indices
    class GeorgiaCoastVideos < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 5, collection: 'georgia_coast_videos')
        @document = document
        @record = CoreDataConnector::Item.find_by(uuid: document[:uuid])
      end

      def enhance
        @document[:thumbnail_url] = Ecds::Helpers.thumbnail_url(@document[:provider], @document[:embed_id])
        @document[:embed_url] = Ecds::Helpers.embed_url(@document[:provider], @document[:embed_id])
        @document[:places] = places unless @document[:places].nil?
        @document[:location] = @document[:places].map { |p| p[:location] }.compact.first unless @document[:places].nil?
        @document
      end
    end
  end
end
