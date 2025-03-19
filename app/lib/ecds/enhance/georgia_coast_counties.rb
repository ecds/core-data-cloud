# frozen_string_literal: true

require 'elasticsearch'

module Ecds
  module Enhance
    #
    # Add extra properties to Georgia Coast Place records
    #
    class GeorgiaCoastCounties < Ecds::Enhance::GeorgiaCoast
      def initialize(document)
        super
        @documenter = Ecds::Document.new(project_model_id: 6, collection: 'georgia_coast_places')
        @document = document
      end

      def enhance
        @document[:places] = add_places(@document[:places]) unless @document[:places].nil?
        @document[:map_layers] = collect_map_layers
        @document[:places] = nil
        @document[:tmp_map_layers] = nil
        @document
      end
    end
  end
end
